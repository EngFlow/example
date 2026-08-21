package main

import (
	"fmt"
	"sync"
)

// fakeSimulatorControl is an in-memory SimulatorControl used to test
// SimulatorManager's lease/slot/reference-count logic without shelling out to
// xcrun simctl.
type fakeSimulatorControl struct {
	mu sync.Mutex

	udidCounter int

	createBaseCalls int

	cloneCalls []string // clone device names, in call order
	// cloneGate, if non-nil, blocks the first Clone call until the test sends
	// (or closes) it -- used to deterministically exercise in-flight clone
	// sharing between concurrent Lease calls.
	cloneGate      chan struct{}
	cloneGateOnce  sync.Once
	cloneGateFired bool

	ensureBootedCalls []SimulatorUDID
	// ensureBootedErrs are one-shot: each error is returned exactly once for
	// the matching UDID, then cleared, so a retry can succeed.
	ensureBootedErrs map[SimulatorUDID]error

	deleteCalls []SimulatorUDID
	deleteErrs  map[SimulatorUDID]error

	cleanTempFilesCalls []SimulatorUDID
}

func newFakeSimulatorControl() *fakeSimulatorControl {
	return &fakeSimulatorControl{
		ensureBootedErrs: make(map[SimulatorUDID]error),
		deleteErrs:       make(map[SimulatorUDID]error),
	}
}

func (f *fakeSimulatorControl) nextUDID() SimulatorUDID {
	f.udidCounter++
	return fmt.Sprintf("udid-%d", f.udidCounter)
}

func (f *fakeSimulatorControl) CreateBase(name string, config SimulatorConfig, runtimeIdentifier string) (SimulatorUDID, error) {
	f.mu.Lock()
	f.createBaseCalls++
	udid := f.nextUDID()
	f.mu.Unlock()
	return udid, nil
}

func (f *fakeSimulatorControl) Clone(baseSimulator SimulatorUDID, name string, deviceType string, runtimeIdentifier string, postBoot *string) (SimulatorUDID, error) {
	f.mu.Lock()
	f.cloneCalls = append(f.cloneCalls, name)
	gate := f.cloneGate
	alreadyFired := f.cloneGateFired
	f.mu.Unlock()

	if gate != nil && !alreadyFired {
		f.cloneGateOnce.Do(func() {
			<-gate
			f.mu.Lock()
			f.cloneGateFired = true
			f.mu.Unlock()
		})
	}

	f.mu.Lock()
	udid := f.nextUDID()
	f.mu.Unlock()
	return udid, nil
}

func (f *fakeSimulatorControl) EnsureBooted(simulator SimulatorUDID, context string) error {
	f.mu.Lock()
	defer f.mu.Unlock()

	f.ensureBootedCalls = append(f.ensureBootedCalls, simulator)
	if err, ok := f.ensureBootedErrs[simulator]; ok {
		delete(f.ensureBootedErrs, simulator)
		return err
	}
	return nil
}

func (f *fakeSimulatorControl) CleanTempFiles(simulator SimulatorUDID) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.cleanTempFilesCalls = append(f.cleanTempFilesCalls, simulator)
}

func (f *fakeSimulatorControl) Delete(simulator SimulatorUDID, name string, context string) error {
	f.mu.Lock()
	defer f.mu.Unlock()

	f.deleteCalls = append(f.deleteCalls, simulator)
	return f.deleteErrs[simulator]
}

func (f *fakeSimulatorControl) GetExisting(name string, deviceType string, runtimeIdentifier string, context string) (string, error) {
	// SimulatorManager never calls this directly -- it's only used internally
	// by RealSimulatorControl's own createBase/clone rediscovery logic, which
	// this fake doesn't need to replicate.
	return "", nil
}

// fakeLeaseStore is an in-memory LeaseStore for testing RestoreLeases and
// persistence side effects without touching disk.
type fakeLeaseStore struct {
	mu     sync.Mutex
	loaded []PersistedLease
	saved  [][]PersistedLease
}

func (f *fakeLeaseStore) Load() []PersistedLease {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.loaded
}

func (f *fakeLeaseStore) Save(leases []PersistedLease) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.saved = append(f.saved, leases)
}

func (f *fakeLeaseStore) lastSaved() []PersistedLease {
	f.mu.Lock()
	defer f.mu.Unlock()
	if len(f.saved) == 0 {
		return nil
	}
	return f.saved[len(f.saved)-1]
}
