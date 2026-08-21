package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"sync"
	"syscall"
	"time"
)

type SimulatorManagerError struct {
	kind    string
	udid    SimulatorUDID
	message string
}

func (e *SimulatorManagerError) Error() string {
	if e.message != "" {
		return e.message
	}
	return e.kind
}

var (
	ErrAlreadyLeased = &SimulatorManagerError{kind: "alreadyLeased"}
	ErrNoLease       = &SimulatorManagerError{kind: "noLease"}
	ErrLeaserExited  = &SimulatorManagerError{kind: "leaserExited"}
)

func NewAlreadyLeasedError(udid SimulatorUDID) error {
	return &SimulatorManagerError{kind: "alreadyLeased", udid: udid}
}

type simulatorLease struct {
	udid            SimulatorUDID
	config          SimulatorConfig
	exclusive       bool
	slotIndex       int
	leaserStartTime *uint64
}

type simulatorSlot struct {
	kind      string
	udid      SimulatorUDID
	exclusive bool
	task      *resultBroadcaster
	cancel    context.CancelFunc
}

const (
	slotEmpty           = "empty"
	slotPendingCreation = "pendingCreation"
	slotActive          = "active"
	slotPendingDeletion = "pendingDeletion"
	slotDeleting        = "deleting"
)

func (s simulatorSlot) sortOrder() int {
	switch s.kind {
	case slotActive:
		return 0
	case slotPendingCreation:
		return 1
	case slotPendingDeletion:
		return 2
	case slotEmpty:
		return 3
	case slotDeleting:
		return 4
	default:
		return 5
	}
}

type SimulatorManager struct {
	simulatorControl SimulatorControl

	mu                sync.Mutex
	simulatorSlots    map[SimulatorConfig][]simulatorSlot
	referenceCount    map[SimulatorUDID]int
	leases            map[int32]simulatorLease
	leaserExitWatches map[int32]context.CancelFunc

	getBaseSimulatorTasks map[SimulatorConfig]*resultBroadcaster

	deleteIdleAfter             uint16
	deleteRecentlyUsedIdleAfter uint16
	deleteOnPIDExit             bool

	leaseStore LeaseStore

	recentlyLeased *LRUSet[SimulatorConfig]

	startupProcessPaths []string
	postBoot            *string
	childProcessCancel  []context.CancelFunc
}

func NewSimulatorManager(
	simulatorControl SimulatorControl,
	deleteRecentlyUsedIdleAfter uint16,
	deleteIdleAfter uint16,
	recentlyUsedCapacity int,
	deleteOnPIDExit bool,
	startupProcesses []string,
	postBoot *string,
	leaseStore LeaseStore,
) *SimulatorManager {
	if err := os.Chdir("/tmp"); err != nil {
		logger.Warn("Failed to change directory to /tmp", "error", err)
	}

	return &SimulatorManager{
		simulatorControl:            simulatorControl,
		simulatorSlots:              make(map[SimulatorConfig][]simulatorSlot),
		referenceCount:              make(map[SimulatorUDID]int),
		leases:                      make(map[int32]simulatorLease),
		leaserExitWatches:           make(map[int32]context.CancelFunc),
		getBaseSimulatorTasks:       make(map[SimulatorConfig]*resultBroadcaster),
		deleteIdleAfter:             deleteIdleAfter,
		deleteRecentlyUsedIdleAfter: deleteRecentlyUsedIdleAfter,
		deleteOnPIDExit:             deleteOnPIDExit,
		leaseStore:                  leaseStore,
		recentlyLeased:              NewLRUSet[SimulatorConfig](recentlyUsedCapacity),
		startupProcessPaths:         startupProcesses,
		postBoot:                    postBoot,
	}
}

func (sm *SimulatorManager) StartChildProcesses() error {
	for _, path := range sm.startupProcessPaths {
		ctx, cancel := context.WithCancel(context.Background())
		sm.childProcessCancel = append(sm.childProcessCancel, cancel)
		go sm.startChildProcess(ctx, path)
	}
	return nil
}

func (sm *SimulatorManager) startChildProcess(ctx context.Context, path string) {
	childProcessLogger.Info("Starting child process", "path", path)

	cmd := exec.Command(path)

	outPTY, err := NewPTY()
	if err != nil {
		childProcessLogger.Error("Failed to create output PTY", "path", path, "error", err)
		return
	}

	errPTY, err := NewPTY()
	if err != nil {
		childProcessLogger.Error("Failed to create error PTY", "path", path, "error", err)
		return
	}

	cmd.Stdout = os.NewFile(uintptr(outPTY.Child), "stdout")
	cmd.Stderr = os.NewFile(uintptr(errPTY.Child), "stderr")

	go watchFD(outPTY.Parent, func(line string) {
		childProcessLogger.Info(fmt.Sprintf("[%s] %s", path, line))
	})

	go watchFD(errPTY.Parent, func(line string) {
		childProcessLogger.Error(fmt.Sprintf("[%s] %s", path, line))
	})

	if err := cmd.Start(); err != nil {
		childProcessLogger.Error("Failed to start child process", "path", path, "error", err)
		return
	}

	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
	}()

	select {
	case <-ctx.Done():
		_ = cmd.Process.Kill()
		return
	case err := <-done:
		if err != nil {
			childProcessLogger.Warn("Child process exited with error", "path", path, "error", err)
		} else {
			childProcessLogger.Warn("Child process exited", "path", path)
		}
	}
}

func watchFD(fd int, onLine func(string)) {
	file := os.NewFile(uintptr(fd), "pipe")
	defer file.Close()

	buf := make([]byte, 4096)
	var lineBuffer []byte

	for {
		n, err := file.Read(buf)
		if err != nil {
			if err != io.EOF {
				logger.Error("Error reading from FD", "error", err)
			}
			break
		}

		lineBuffer = append(lineBuffer, buf[:n]...)

		for {
			newlineIdx := -1
			for i, b := range lineBuffer {
				if b == '\n' {
					newlineIdx = i
					break
				}
			}

			if newlineIdx == -1 {
				break
			}

			line := string(lineBuffer[:newlineIdx])
			onLine(line)
			lineBuffer = lineBuffer[newlineIdx+1:]
		}
	}
}

func (sm *SimulatorManager) RestoreLeases() {
	if sm.leaseStore == nil {
		return
	}

	persisted := sm.leaseStore.Load()
	if len(persisted) == 0 {
		return
	}

	sm.mu.Lock()
	defer sm.mu.Unlock()

	adopted := 0
	dropped := 0

	for _, lease := range persisted {
		if !sm.leaserSurvived(lease) {
			dropped++
			continue
		}

		if !sm.canAdopt(lease) {
			logger.Error("Not restoring conflicting lease", "pid", lease.PID, "udid", lease.UDID)
			dropped++
			continue
		}

		sm.leases[lease.PID] = simulatorLease{
			udid:            lease.UDID,
			config:          lease.Config,
			exclusive:       lease.Exclusive,
			slotIndex:       lease.SlotIndex,
			leaserStartTime: lease.LeaserStartTime,
		}

		slots := sm.simulatorSlots[lease.Config]
		for len(slots) <= lease.SlotIndex {
			slots = append(slots, simulatorSlot{kind: slotEmpty})
		}
		slots[lease.SlotIndex] = simulatorSlot{
			kind:      slotActive,
			udid:      lease.UDID,
			exclusive: lease.Exclusive,
		}
		sm.simulatorSlots[lease.Config] = slots

		sm.incrementReferenceCount(lease.UDID)

		if sm.deleteOnPIDExit {
			sm.registerReleaseOnExit(lease.PID)
		}

		adopted++
	}

	logger.Info("Restored leases from previous simulator manager", "adopted", adopted, "dropped", dropped)

	sm.persistLeases()
}

func (sm *SimulatorManager) leaserSurvived(lease PersistedLease) bool {
	if !processIsRunning(lease.PID) {
		return false
	}

	if lease.LeaserStartTime == nil {
		return true
	}

	currentStart := processStartTime(lease.PID)
	if currentStart == nil {
		return false
	}

	if *currentStart != *lease.LeaserStartTime {
		logger.Info("PID is running but started at a different time; treating as exited", "pid", lease.PID)
		return false
	}

	return true
}

func (sm *SimulatorManager) canAdopt(lease PersistedLease) bool {
	for _, existing := range sm.leases {
		if existing.udid == lease.UDID && (existing.exclusive || lease.Exclusive) {
			return false
		}

		if existing.config == lease.Config &&
			existing.slotIndex == lease.SlotIndex &&
			existing.udid != lease.UDID {
			return false
		}
	}
	return true
}

func (sm *SimulatorManager) persistLeases() {
	if sm.leaseStore == nil {
		return
	}

	leases := make([]PersistedLease, 0, len(sm.leases))
	for pid, lease := range sm.leases {
		leases = append(leases, PersistedLease{
			PID:             pid,
			LeaserStartTime: lease.leaserStartTime,
			UDID:            lease.udid,
			Config:          lease.config,
			Exclusive:       lease.exclusive,
			SlotIndex:       lease.slotIndex,
		})
	}

	sm.leaseStore.Save(leases)
}

func (sm *SimulatorManager) Lease(leaser int32, exclusive bool, config SimulatorConfig) (SimulatorUDID, error) {
	sm.mu.Lock()
	if existingLease, ok := sm.leases[leaser]; ok {
		sm.mu.Unlock()
		return "", NewAlreadyLeasedError(existingLease.udid)
	}
	sm.mu.Unlock()

	logger.Info("Leasing simulator", "exclusive", exclusive, "config", config, "pid", leaser)

	if sm.deleteOnPIDExit && !processIsRunning(leaser) {
		logger.Info("PID exited before its lease could be provisioned", "pid", leaser)
		return "", ErrLeaserExited
	}

	simulator, slotIndex, err := sm.getSimulator(config, exclusive)
	if err != nil {
		return "", err
	}

	sm.mu.Lock()
	sm.recentlyLeased.Insert(config)

	sm.leases[leaser] = simulatorLease{
		udid:            simulator,
		config:          config,
		exclusive:       exclusive,
		slotIndex:       slotIndex,
		leaserStartTime: processStartTime(leaser),
	}
	sm.persistLeases()
	sm.mu.Unlock()

	if sm.deleteOnPIDExit && !processIsRunning(leaser) {
		logger.Info("PID exited while simulator was being provisioned; returning to pool", "pid", leaser, "udid", simulator)
		_ = sm.Release(leaser)
		return "", ErrLeaserExited
	}

	logger.Info("Leased simulator", "udid", simulator, "pid", leaser)

	if sm.deleteOnPIDExit {
		sm.mu.Lock()
		sm.registerReleaseOnExit(leaser)
		sm.mu.Unlock()
	}

	return simulator, nil
}

func (sm *SimulatorManager) LiveLeaseCount() int {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	count := 0
	for pid := range sm.leases {
		if processIsRunning(pid) {
			count++
		}
	}
	return count
}

func (sm *SimulatorManager) Release(leaser int32) error {
	sm.mu.Lock()
	lease, ok := sm.leases[leaser]
	if !ok {
		sm.mu.Unlock()
		return ErrNoLease
	}
	delete(sm.leases, leaser)

	logger.Info("Releasing simulator", "udid", lease.udid, "pid", leaser)

	sm.persistLeases()
	sm.removeReleaseOnExit(leaser)
	sm.mu.Unlock()

	sm.simulatorControl.CleanTempFiles(lease.udid)

	return sm.decrementReferenceCount(lease.udid, lease.config, lease.slotIndex)
}

func (sm *SimulatorManager) getBase(config SimulatorConfig) (SimulatorUDID, error) {
	sm.mu.Lock()
	if existing, ok := sm.getBaseSimulatorTasks[config]; ok {
		sm.mu.Unlock()
		result := existing.wait()
		return result.udid, result.err
	}

	broadcaster := newResultBroadcaster()
	sm.getBaseSimulatorTasks[config] = broadcaster
	sm.mu.Unlock()

	go func() {
		defer func() {
			sm.mu.Lock()
			delete(sm.getBaseSimulatorTasks, config)
			sm.mu.Unlock()
		}()

		logger.Info("Creating base simulator", "config", config)

		baseSimulator, err := sm.simulatorControl.CreateBase(
			config.BaseDeviceName(),
			config,
			config.RuntimeIdentifier(),
		)

		if err == nil {
			logger.Info("Created base simulator", "config", config, "udid", baseSimulator)
		}

		broadcaster.complete(taskResult{udid: baseSimulator, err: err})
	}()

	result := broadcaster.wait()
	return result.udid, result.err
}

func (sm *SimulatorManager) incrementReferenceCount(simulator SimulatorUDID) {
	count := sm.referenceCount[simulator]
	count++
	sm.referenceCount[simulator] = count

	logger.Debug("Reference count increased", "udid", simulator, "count", count)
}

func (sm *SimulatorManager) decrementReferenceCount(simulator SimulatorUDID, config SimulatorConfig, slotIndex int) error {
	sm.mu.Lock()
	count, ok := sm.referenceCount[simulator]
	if !ok {
		sm.mu.Unlock()
		return nil
	}

	count--
	sm.referenceCount[simulator] = count

	logger.Debug("Reference count decreased", "udid", simulator, "count", count)

	if count > 0 {
		sm.mu.Unlock()
		return nil
	}
	sm.mu.Unlock()

	sm.pendingDeletion(simulator, config, slotIndex)
	return nil
}

func (sm *SimulatorManager) getSimulator(config SimulatorConfig, exclusive bool) (SimulatorUDID, int, error) {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	if _, ok := sm.simulatorSlots[config]; !ok {
		sm.simulatorSlots[config] = []simulatorSlot{}
	}

	slots := sm.simulatorSlots[config]
	type indexedSlot struct {
		index int
		slot  simulatorSlot
	}

	sortedSlots := make([]indexedSlot, len(slots))
	for i, slot := range slots {
		sortedSlots[i] = indexedSlot{index: i, slot: slot}
	}

	// Sort by sort order, then by index
	for i := 0; i < len(sortedSlots); i++ {
		for j := i + 1; j < len(sortedSlots); j++ {
			iOrder := sortedSlots[i].slot.sortOrder()
			jOrder := sortedSlots[j].slot.sortOrder()
			if iOrder > jOrder || (iOrder == jOrder && sortedSlots[i].index > sortedSlots[j].index) {
				sortedSlots[i], sortedSlots[j] = sortedSlots[j], sortedSlots[i]
			}
		}
	}

	for _, is := range sortedSlots {
		slot := is.slot
		index := is.index

		switch slot.kind {
		case slotActive:
			if !slot.exclusive && !exclusive {
				sm.mu.Unlock()
				sim, err := sm.reuseSimulator(slot.udid, config, exclusive, index)
				sm.mu.Lock()
				return sim, index, err
			}

		case slotPendingDeletion:
			logger.Info("Turning pending deletion into active simulator", "udid", slot.udid, "exclusive", exclusive)

			sm.simulatorSlots[config][index] = simulatorSlot{
				kind:      slotActive,
				udid:      slot.udid,
				exclusive: exclusive,
			}

			if slot.cancel != nil {
				slot.cancel()
			}

			sm.mu.Unlock()
			sim, err := sm.reuseSimulator(slot.udid, config, exclusive, index)
			sm.mu.Lock()
			return sim, index, err

		case slotEmpty:
			task, cancel := sm.createCloneTask(config, exclusive, index)
			sm.simulatorSlots[config][index] = simulatorSlot{
				kind:      slotPendingCreation,
				task:      task,
				exclusive: exclusive,
				cancel:    cancel,
			}
			sm.mu.Unlock()
			result := task.wait()
			sm.mu.Lock()
			return result.udid, index, result.err

		case slotPendingCreation:
			if !slot.exclusive && !exclusive {
				sm.mu.Unlock()
				result := slot.task.wait()
				if result.err == nil {
					sm.mu.Lock()
					sm.incrementReferenceCount(result.udid)
					sm.mu.Unlock()
				}
				sm.mu.Lock()
				return result.udid, index, result.err
			}
		}
	}

	index := len(sm.simulatorSlots[config])
	task, cancel := sm.createCloneTask(config, exclusive, index)
	sm.simulatorSlots[config] = append(sm.simulatorSlots[config], simulatorSlot{
		kind:      slotPendingCreation,
		task:      task,
		exclusive: exclusive,
		cancel:    cancel,
	})
	sm.mu.Unlock()
	result := task.wait()
	sm.mu.Lock()
	return result.udid, index, result.err
}

func (sm *SimulatorManager) reuseSimulator(simulator SimulatorUDID, config SimulatorConfig, exclusive bool, slotIndex int) (SimulatorUDID, error) {
	sm.mu.Lock()
	sm.incrementReferenceCount(simulator)
	sm.mu.Unlock()

	err := sm.simulatorControl.EnsureBooted(simulator, fmt.Sprintf("getSimulator, reused: %s", config.CloneDeviceName(slotIndex)))
	if err != nil {
		if pe, ok := err.(*ProcessError); ok && pe.ExitCode == 148 {
			logger.Warn("Boot of existing simulator failed; deleting and returning new simulator", "udid", simulator, "error", err)

			sm.mu.Lock()
			_ = sm.delete(simulator, config, slotIndex, false, "getSimulator, reused: "+config.CloneDeviceName(slotIndex))

			task, cancel := sm.createCloneTask(config, exclusive, slotIndex)
			sm.simulatorSlots[config][slotIndex] = simulatorSlot{
				kind:      slotPendingCreation,
				task:      task,
				exclusive: exclusive,
				cancel:    cancel,
			}
			sm.mu.Unlock()

			result := task.wait()
			return result.udid, result.err
		}
		return "", err
	}

	return simulator, nil
}

func (sm *SimulatorManager) createCloneTask(config SimulatorConfig, exclusive bool, slotIndex int) (*resultBroadcaster, context.CancelFunc) {
	ctx, cancel := context.WithCancel(context.Background())
	broadcaster := newResultBroadcaster()

	go func() {
		baseUDID, err := sm.getBase(config)
		if err != nil {
			sm.mu.Lock()
			sm.simulatorSlots[config][slotIndex] = simulatorSlot{kind: slotEmpty}
			sm.mu.Unlock()
			broadcaster.complete(taskResult{err: err})
			return
		}

		if ctx.Err() != nil {
			sm.mu.Lock()
			sm.simulatorSlots[config][slotIndex] = simulatorSlot{kind: slotEmpty}
			sm.mu.Unlock()
			broadcaster.complete(taskResult{err: ctx.Err()})
			return
		}

		simulator, err := sm.simulatorControl.Clone(
			baseUDID,
			config.CloneDeviceName(slotIndex),
			config.DeviceType,
			config.RuntimeIdentifier(),
			sm.postBoot,
		)

		if err != nil {
			sm.mu.Lock()
			sm.simulatorSlots[config][slotIndex] = simulatorSlot{kind: slotEmpty}
			sm.mu.Unlock()
			broadcaster.complete(taskResult{err: err})
			return
		}

		sm.mu.Lock()
		sm.simulatorSlots[config][slotIndex] = simulatorSlot{
			kind:      slotActive,
			udid:      simulator,
			exclusive: exclusive,
		}
		sm.incrementReferenceCount(simulator)
		sm.mu.Unlock()

		broadcaster.complete(taskResult{udid: simulator, err: nil})
	}()

	return broadcaster, cancel
}

func (sm *SimulatorManager) registerReleaseOnExit(leaser int32) {
	ctx, cancel := context.WithCancel(context.Background())
	sm.leaserExitWatches[leaser] = cancel

	go func() {
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if !processIsRunning(leaser) {
					logger.Debug("PID exited", "pid", leaser)
					_ = sm.Release(leaser)
					return
				}
			}
		}
	}()
}

func (sm *SimulatorManager) removeReleaseOnExit(leaser int32) {
	if cancel, ok := sm.leaserExitWatches[leaser]; ok {
		delete(sm.leaserExitWatches, leaser)
		cancel()
	}
}

func (sm *SimulatorManager) pendingDeletion(simulator SimulatorUDID, config SimulatorConfig, slotIndex int) {
	if sm.deleteIdleAfter == 0 && sm.deleteRecentlyUsedIdleAfter == 0 {
		sm.mu.Lock()
		_ = sm.delete(simulator, config, slotIndex, true, "pendingDeletion immediate")
		sm.mu.Unlock()
		return
	}

	ctx, cancel := context.WithCancel(context.Background())

	sm.mu.Lock()
	sm.simulatorSlots[config][slotIndex] = simulatorSlot{
		kind:   slotPendingDeletion,
		udid:   simulator,
		cancel: cancel,
	}
	sm.mu.Unlock()

	go func() {
		logger.Info("Scheduling delete of simulator", "udid", simulator, "idleAfter", sm.deleteIdleAfter, "recentlyUsedIdleAfter", sm.deleteRecentlyUsedIdleAfter)

		now := time.Now()
		shortDeadline := now.Add(time.Duration(sm.deleteIdleAfter) * time.Second)
		recentlyUsedDeadline := now.Add(time.Duration(sm.deleteRecentlyUsedIdleAfter) * time.Second)

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				var remainingTime time.Duration
				sm.mu.Lock()
				if sm.recentlyLeased.Contains(config) {
					remainingTime = time.Until(recentlyUsedDeadline)
				} else {
					remainingTime = time.Until(shortDeadline)
				}
				sm.mu.Unlock()

				if remainingTime <= 0 {
					sm.mu.Lock()
					slots := sm.simulatorSlots[config]
					if slotIndex < len(slots) {
						slot := slots[slotIndex]
						if slot.kind == slotPendingDeletion && slot.udid == simulator {
							_ = sm.delete(simulator, config, slotIndex, true, "pendingDeletion delayed")
						}
					}
					sm.mu.Unlock()
					return
				}
			}
		}
	}()
}

func (sm *SimulatorManager) delete(simulator SimulatorUDID, config SimulatorConfig, slotIndex int, cleanUpSlots bool, context string) error {
	name := config.CloneDeviceName(slotIndex)

	logger.Info("Deleting simulator", "udid", simulator, "name", name)

	sm.simulatorSlots[config][slotIndex] = simulatorSlot{
		kind: slotDeleting,
		udid: simulator,
	}

	delete(sm.referenceCount, simulator)

	defer func() {
		sm.simulatorSlots[config][slotIndex] = simulatorSlot{kind: slotEmpty}

		if cleanUpSlots {
			slots := sm.simulatorSlots[config]
			for len(slots) > 0 && slots[len(slots)-1].kind == slotEmpty {
				slots = slots[:len(slots)-1]
			}
			sm.simulatorSlots[config] = slots
		}
	}()

	err := sm.simulatorControl.Delete(simulator, name, context)
	if err == nil {
		logger.Info("Deleted simulator", "udid", simulator, "name", name)
	}

	return err
}

func (sm *SimulatorManager) Close() {
	for _, cancel := range sm.childProcessCancel {
		cancel()
	}
}

func processIsRunning(pid int32) bool {
	err := syscall.Kill(int(pid), 0)
	if err == nil {
		return true
	}
	return err != syscall.ESRCH
}
