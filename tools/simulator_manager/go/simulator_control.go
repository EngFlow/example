package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type SimulatorConfig struct {
	DeviceType string `json:"deviceType"`
	OS         string `json:"os"`
	Version    string `json:"version"`
}

func (c SimulatorConfig) String() string {
	return fmt.Sprintf("%s (%s %s)", c.DeviceType, c.OS, c.Version)
}

func (c SimulatorConfig) BaseDeviceName() string {
	return fmt.Sprintf("EXAMPLE_BAZEL_BASE_%s_%s", c.DeviceType, c.Version)
}

func (c SimulatorConfig) CloneDeviceName(index int) string {
	return fmt.Sprintf("EXAMPLE_BAZEL_CLONE_%s_%s_%d", c.DeviceType, c.Version, index)
}

func (c SimulatorConfig) RuntimeIdentifier() string {
	runtimeVersion := strings.ReplaceAll(c.Version, ".", "-")
	return fmt.Sprintf("com.apple.CoreSimulator.SimRuntime.%s-%s", c.OS, runtimeVersion)
}

type SimCtlDevices struct {
	Devices map[string][]SimCtlDevice `json:"devices"`
}

type SimCtlDevice struct {
	Name  string `json:"name"`
	UDID  string `json:"udid"`
	State string `json:"state"`
}

type ProcessError struct {
	Command  string
	Context  string
	ExitCode int
	StdOut   string
	StdErr   string
}

func (e *ProcessError) Error() string {
	contextStr := ""
	if e.Context != "" {
		contextStr = fmt.Sprintf(" (%s)", e.Context)
	}
	return fmt.Sprintf("\"%s\"%s failed with exit code %d:\n%s%s",
		e.Command, contextStr, e.ExitCode, e.StdOut, e.StdErr)
}

type SimulatorControl interface {
	// CreateBase creates a base simulator with the given config.
	//
	// It also boots and shuts down the simulator, making it ready for cloning.
	//
	// If an existing simulator with the same name already exists, that is returned instead of
	// creating a new one. This is to support the simulator manager being restarted and losing state.
	CreateBase(name string, config SimulatorConfig, runtimeIdentifier string) (SimulatorUDID, error)

	// Clone clones a base simulator.
	//
	// It also boots the cloned simulator, making it ready for use.
	//
	// If an existing simulator with the same name already exists, that is returned instead of
	// creating a new one. This is to support the simulator manager being restarted and losing state.
	Clone(baseSimulator SimulatorUDID, name string, deviceType string, runtimeIdentifier string, postBoot *string) (SimulatorUDID, error)

	EnsureBooted(simulator SimulatorUDID, context string) error

	CleanTempFiles(simulator SimulatorUDID)

	Delete(simulator SimulatorUDID, name string, context string) error

	GetExisting(name string, deviceType string, runtimeIdentifier string, context string) (string, error)

	// RunningSimulators returns every currently-booted simulator named `name`,
	// across all runtimes. Used as a lease-time sanity check: a shared device
	// should only ever have one real, booted simulator behind it, so finding
	// more than one indicates the sharing/reuse logic let a duplicate device
	// come into existence.
	RunningSimulators(name string) ([]SimCtlDevice, error)
}

type RealSimulatorControl struct {
	createBaseTasks     map[string]*resultBroadcaster
	createBaseTasksLock sync.Mutex

	cloneTasks     map[string]*resultBroadcaster
	cloneTasksLock sync.Mutex

	deleteAndExistenceMutexes     map[string]*deleteOrExistenceMutexEntry
	deleteAndExistenceMutexesLock sync.Mutex
}

type taskResult struct {
	udid SimulatorUDID
	err  error
}

// resultBroadcaster lets any number of callers await the same eventual
// taskResult without consuming it. A plain channel can't do this safely: if
// two goroutines both receive from the one channel used to coalesce a single
// in-flight CreateBase/Clone request, only the first gets the real value --
// the second gets the channel's zero value (an empty UDID with a nil error,
// i.e. a phantom successful lease) once the channel is drained and closed.
// Waiting on a channel that's closed once, then reading a result set before
// that close, delivers the same value to every waiter instead.
type resultBroadcaster struct {
	done   chan struct{}
	result taskResult
}

func newResultBroadcaster() *resultBroadcaster {
	return &resultBroadcaster{done: make(chan struct{})}
}

func (b *resultBroadcaster) complete(result taskResult) {
	b.result = result
	close(b.done)
}

func (b *resultBroadcaster) wait() taskResult {
	<-b.done
	return b.result
}

type deleteOrExistenceMutexEntry struct {
	mutex *SimulatorDeleteOrExistenceMutex
	count int
}

func NewRealSimulatorControl() *RealSimulatorControl {
	return &RealSimulatorControl{
		createBaseTasks:           make(map[string]*resultBroadcaster),
		cloneTasks:                make(map[string]*resultBroadcaster),
		deleteAndExistenceMutexes: make(map[string]*deleteOrExistenceMutexEntry),
	}
}

func (r *RealSimulatorControl) CreateBase(name string, config SimulatorConfig, runtimeIdentifier string) (SimulatorUDID, error) {
	r.createBaseTasksLock.Lock()
	if existing, ok := r.createBaseTasks[name]; ok {
		r.createBaseTasksLock.Unlock()
		result := existing.wait()
		return result.udid, result.err
	}

	broadcaster := newResultBroadcaster()
	r.createBaseTasks[name] = broadcaster
	r.createBaseTasksLock.Unlock()

	go func() {
		defer func() {
			r.createBaseTasksLock.Lock()
			delete(r.createBaseTasks, name)
			r.createBaseTasksLock.Unlock()
		}()

		udid, err := r.createBaseImpl(name, config, runtimeIdentifier)
		broadcaster.complete(taskResult{udid: udid, err: err})
	}()

	result := broadcaster.wait()
	return result.udid, result.err
}

func (r *RealSimulatorControl) createBaseImpl(name string, config SimulatorConfig, runtimeIdentifier string) (SimulatorUDID, error) {
	if existingUDID, err := r.GetExisting(name, config.DeviceType, runtimeIdentifier, "createBase"); err == nil && existingUDID != "" {
		simulatorControlLogger.Info("Base simulator already exists, skipping creation", "name", name, "udid", existingUDID)

		if err := r.shutdown(existingUDID, "createBase existing: "+name); err != nil {
			simulatorControlLogger.Error("Failed to set up base simulator; deleting", "name", name, "udid", existingUDID)
			_ = r.Delete(existingUDID, name, "createBase existing: "+name)
			return "", err
		}

		return existingUDID, nil
	}

	simulatorControlLogger.Info("Creating base simulator", "config", config, "name", name)

	udid, err := simctl([]string{"create", name, config.DeviceType, runtimeIdentifier}, "")
	if err != nil {
		return "", err
	}
	udid = strings.TrimSpace(udid)

	if err := r.EnsureBooted(udid, "createBase new: "+name); err != nil {
		simulatorControlLogger.Error("Failed to set up base simulator; deleting", "name", name, "udid", udid)
		_ = r.Delete(udid, name, "createBase new: "+name)
		return "", err
	}

	// Give the simulator some time to do some post-boot processing
	time.Sleep(5 * time.Second)

	if err := r.shutdown(udid, "createBase new: "+name); err != nil {
		simulatorControlLogger.Error("Failed to set up base simulator; deleting", "name", name, "udid", udid)
		_ = r.Delete(udid, name, "createBase new: "+name)
		return "", err
	}

	simulatorControlLogger.Info("Created base simulator", "config", config, "name", name, "udid", udid)

	return udid, nil
}

func (r *RealSimulatorControl) Clone(baseSimulator SimulatorUDID, name string, deviceType string, runtimeIdentifier string, postBoot *string) (SimulatorUDID, error) {
	r.cloneTasksLock.Lock()
	if existing, ok := r.cloneTasks[name]; ok {
		r.cloneTasksLock.Unlock()
		result := existing.wait()
		return result.udid, result.err
	}

	broadcaster := newResultBroadcaster()
	r.cloneTasks[name] = broadcaster
	r.cloneTasksLock.Unlock()

	go func() {
		defer func() {
			r.cloneTasksLock.Lock()
			delete(r.cloneTasks, name)
			r.cloneTasksLock.Unlock()
		}()

		udid, err := r.cloneImpl(baseSimulator, name, deviceType, runtimeIdentifier, postBoot)
		broadcaster.complete(taskResult{udid: udid, err: err})
	}()

	result := broadcaster.wait()
	return result.udid, result.err
}

func (r *RealSimulatorControl) cloneImpl(baseSimulator SimulatorUDID, name string, deviceType string, runtimeIdentifier string, postBoot *string) (SimulatorUDID, error) {
	var udid string
	var isExisting bool

	if existingUDID, err := r.GetExisting(name, deviceType, runtimeIdentifier, "clone"); err == nil && existingUDID != "" {
		udid = existingUDID
		isExisting = true

		simulatorControlLogger.Info("Cloned simulator already exists, skipping creation", "name", name, "udid", udid)

		if err := r.EnsureBooted(udid, "clone, existing: "+name); err != nil {
			return "", err
		}
	} else {
		isExisting = false

		simulatorControlLogger.Info("Cloning base simulator", "base", baseSimulator, "name", name)

		var err error
		udid, err = simctl([]string{"clone", baseSimulator, name}, "")
		if err != nil {
			return "", err
		}
		udid = strings.TrimSpace(udid)

		simulatorControlLogger.Info("Cloned base simulator", "base", baseSimulator, "name", name, "udid", udid)

		if err := r.EnsureBooted(udid, "clone, new: "+name); err != nil {
			return "", err
		}
	}

	if postBoot != nil && *postBoot != "" {
		simulatorControlLogger.Info("Running post-boot script", "script", *postBoot, "udid", udid)

		cmd := exec.Command(*postBoot)
		cmd.Env = append(os.Environ(), "SIMULATOR_UDID="+udid)
		if err := cmd.Run(); err != nil {
			return "", fmt.Errorf("postBoot failed (isExisting: %v): %w", isExisting, err)
		}
	}

	return udid, nil
}

func (r *RealSimulatorControl) shutdown(simulator SimulatorUDID, context string) error {
	_, err := simctl([]string{"shutdown", simulator}, context)
	if err != nil {
		if pe, ok := err.(*ProcessError); ok && pe.ExitCode == 149 {
			simulatorControlLogger.Warn("Shutdown failed, but probably already shut down", "error", err)
			return nil
		}
		return err
	}
	return nil
}

func (r *RealSimulatorControl) CleanTempFiles(simulator SimulatorUDID) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return
	}

	deadCachesPath := filepath.Join(homeDir, "Library/Developer/CoreSimulator/Devices", simulator,
		"data/Library/Caches/com.apple.containermanagerd/Dead")

	contents, err := os.ReadDir(deadCachesPath)
	if err != nil {
		return
	}

	for _, item := range contents {
		itemPath := filepath.Join(deadCachesPath, item.Name())
		_ = os.RemoveAll(itemPath)
	}
}

func (r *RealSimulatorControl) Delete(simulator SimulatorUDID, name string, context string) error {
	return r.deleteAndExistenceMutex(name, func(mutex *SimulatorDeleteOrExistenceMutex) error {
		return mutex.unlockedDelete(simulator, context)
	})
}

func (r *RealSimulatorControl) RunningSimulators(name string) ([]SimCtlDevice, error) {
	output, err := simctl([]string{"list", "devices", "-j"}, "assertAtMostOneRunning")
	if err != nil {
		return nil, err
	}

	var devices SimCtlDevices
	if err := json.Unmarshal([]byte(output), &devices); err != nil {
		simulatorControlLogger.Error("Failed to decode 'simctl list devices -j'", "error", err, "output", output)
		return nil, fmt.Errorf("failed to decode output: %w - %s", err, output)
	}

	var running []SimCtlDevice
	for _, deviceList := range devices.Devices {
		for _, device := range deviceList {
			if device.Name == name && device.State == "Booted" {
				running = append(running, device)
			}
		}
	}
	return running, nil
}

func (r *RealSimulatorControl) GetExisting(name string, deviceType string, runtimeIdentifier string, context string) (string, error) {
	var result string
	err := r.deleteAndExistenceMutex(name, func(mutex *SimulatorDeleteOrExistenceMutex) error {
		var err error
		result, err = mutex.unlockedGetExisting(name, deviceType, runtimeIdentifier, context)
		return err
	})
	return result, err
}

func (r *RealSimulatorControl) EnsureBooted(simulator SimulatorUDID, context string) error {
	for retriesLeft := 1; retriesLeft >= 0; retriesLeft-- {
		_, err := simctl([]string{"bootstatus", simulator, "-b"}, context)
		if err == nil {
			break
		}

		if pe, ok := err.(*ProcessError); ok && pe.ExitCode == 149 && retriesLeft > 0 {
			simulatorControlLogger.Warn("Boot failed, but probably already booted", "simulator", simulator, "error", err)
			continue
		}

		return err
	}
	return nil
}

func (r *RealSimulatorControl) deleteAndExistenceMutex(name string, fn func(*SimulatorDeleteOrExistenceMutex) error) error {
	r.deleteAndExistenceMutexesLock.Lock()
	entry, ok := r.deleteAndExistenceMutexes[name]
	if !ok {
		entry = &deleteOrExistenceMutexEntry{
			mutex: NewSimulatorDeleteOrExistenceMutex(),
			count: 0,
		}
		r.deleteAndExistenceMutexes[name] = entry
	}
	entry.count++
	r.deleteAndExistenceMutexesLock.Unlock()

	defer func() {
		r.deleteAndExistenceMutexesLock.Lock()
		entry.count--
		if entry.count == 0 {
			delete(r.deleteAndExistenceMutexes, name)
		}
		r.deleteAndExistenceMutexesLock.Unlock()
	}()

	return entry.mutex.WithLock(fn)
}

type SimulatorDeleteOrExistenceMutex struct {
	mu sync.Mutex
}

func NewSimulatorDeleteOrExistenceMutex() *SimulatorDeleteOrExistenceMutex {
	return &SimulatorDeleteOrExistenceMutex{}
}

func (m *SimulatorDeleteOrExistenceMutex) WithLock(fn func(*SimulatorDeleteOrExistenceMutex) error) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	return fn(m)
}

func (m *SimulatorDeleteOrExistenceMutex) unlockedGetExisting(name string, deviceType string, runtimeIdentifier string, context string) (string, error) {
	simulatorControlLogger.Debug("Trying to find existing simulator", "name", name)

	output, err := simctl([]string{"list", "devices", "-j", deviceType}, context)
	if err != nil {
		return "", err
	}

	var devices SimCtlDevices
	if err := json.Unmarshal([]byte(output), &devices); err != nil {
		simulatorControlLogger.Error("Failed to decode 'simctl list devices -j'", "error", err, "output", output)
		return "", fmt.Errorf("failed to decode output: %w - %s", err, output)
	}

	if deviceList, ok := devices.Devices[runtimeIdentifier]; ok {
		for _, device := range deviceList {
			if device.Name == name {
				udid := device.UDID
				simulatorControlLogger.Debug("Found existing simulator", "name", name, "udid", udid)

				homeDir, _ := os.UserHomeDir()
				devicePath := filepath.Join(homeDir, "Library/Developer/CoreSimulator/Devices", udid)
				if _, err := os.Stat(devicePath); os.IsNotExist(err) {
					simulatorControlLogger.Debug("Simulator doesn't actually exist on disk; deleting", "udid", udid)
					_ = m.unlockedDelete(udid, context)
					return "", nil
				}

				return udid, nil
			}
		}
	}

	simulatorControlLogger.Debug("No existing simulator found", "name", name)
	return "", nil
}

func (m *SimulatorDeleteOrExistenceMutex) unlockedDelete(simulator SimulatorUDID, context string) error {
	simulatorControlLogger.Info("Deleting simulator", "udid", simulator)

	if _, err := simctl([]string{"delete", simulator}, context); err != nil {
		simulatorControlLogger.Error("Failed to delete simulator", "udid", simulator, "error", err)
		return err
	}

	simulatorControlLogger.Info("Deleted simulator", "udid", simulator)
	return nil
}

func simctl(args []string, context string) (string, error) {
	return subprocess("/usr/bin/xcrun", append([]string{"simctl"}, args...), nil, context)
}

func subprocess(executable string, args []string, env map[string]string, context string) (string, error) {
	cmd := exec.Command(executable, args...)
	if env != nil {
		cmd.Env = os.Environ()
		for k, v := range env {
			cmd.Env = append(cmd.Env, k+"="+v)
		}
	}

	quotedArgs := make([]string, len(args))
	for i, arg := range args {
		quotedArgs[i] = fmt.Sprintf("'%s'", arg)
	}
	command := fmt.Sprintf("%s %s", executable, strings.Join(quotedArgs, " "))

	simulatorControlLogger.Debug("Running command", "command", command)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		exitCode := 0
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		}
		return "", &ProcessError{
			Command:  command,
			Context:  context,
			ExitCode: exitCode,
			StdOut:   stdout.String(),
			StdErr:   stderr.String(),
		}
	}

	return stdout.String(), nil
}
