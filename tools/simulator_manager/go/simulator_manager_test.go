package main

import (
	"os"
	"os/exec"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func newTestManager(control SimulatorControl, deleteIdleAfter uint16, deleteRecentlyUsedIdleAfter uint16, deleteOnPIDExit bool, leaseStore LeaseStore) *SimulatorManager {
	return NewSimulatorManager(control, deleteRecentlyUsedIdleAfter, deleteIdleAfter, 1, deleteOnPIDExit, nil, nil, leaseStore)
}

func testConfig(deviceType string) SimulatorConfig {
	return SimulatorConfig{DeviceType: deviceType, OS: "iOS", Version: "17.0"}
}

// spawnDeadPID starts and waits for a trivial subprocess to exit, then
// returns its PID. Once a process is reaped, the kernel guarantees
// kill(pid, 0) reports ESRCH for that PID (barring an extremely unlikely
// immediate reuse), making this a reliable "definitely not running" PID.
func spawnDeadPID(t *testing.T) int32 {
	t.Helper()
	cmd := exec.Command("/usr/bin/true")
	require.NoError(t, cmd.Run())
	return int32(cmd.Process.Pid)
}

// spawnLiveProcess starts a long-lived subprocess, killing it automatically
// at test cleanup, and returns its PID.
func spawnLiveProcess(t *testing.T) (*exec.Cmd, int32) {
	t.Helper()
	cmd := exec.Command("/bin/sleep", "30")
	require.NoError(t, cmd.Start())
	t.Cleanup(func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	})
	return cmd, int32(cmd.Process.Pid)
}

func TestLease_NonExclusive_SharesDevice(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	udid1, err := sm.Lease(1, false, cfg)
	require.NoError(t, err)

	udid2, err := sm.Lease(2, false, cfg)
	require.NoError(t, err)

	assert.Equal(t, udid1, udid2, "two non-exclusive leases for the same config should share one device")
	assert.Len(t, control.cloneCalls, 1, "only one clone should have been created")
}

func TestLease_Exclusive_NeverShares(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	udid1, err := sm.Lease(1, true, cfg)
	require.NoError(t, err)

	udid2, err := sm.Lease(2, true, cfg)
	require.NoError(t, err)

	assert.NotEqual(t, udid1, udid2, "exclusive leases must never share a device")
	assert.Len(t, control.cloneCalls, 2)
}

func TestLease_ExclusiveDoesNotShareWithNonExclusive(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	nonExclusive, err := sm.Lease(1, false, cfg)
	require.NoError(t, err)

	exclusive, err := sm.Lease(2, true, cfg)
	require.NoError(t, err)

	assert.NotEqual(t, nonExclusive, exclusive)
}

func TestLease_SamePID_AlreadyLeased(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	udid, err := sm.Lease(1, false, cfg)
	require.NoError(t, err)

	_, err = sm.Lease(1, false, cfg)
	require.Error(t, err)

	sme, ok := err.(*SimulatorManagerError)
	require.True(t, ok, "expected a *SimulatorManagerError, got %T", err)
	assert.Equal(t, "alreadyLeased", sme.kind)
	assert.Equal(t, udid, sme.udid)
}

func TestRelease_NoLease(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)

	err := sm.Release(1)
	assert.Equal(t, ErrNoLease, err)
}

func TestRelease_DeletesImmediatelyWhenIdleAfterIsZero(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	cfg := testConfig("iPhone")

	udid, err := sm.Lease(1, true, cfg)
	require.NoError(t, err)

	require.NoError(t, sm.Release(1))

	assert.Equal(t, []SimulatorUDID{udid}, control.deleteCalls)
	assert.Equal(t, []SimulatorUDID{udid}, control.cleanTempFilesCalls)
}

func TestRelease_SharedDevice_OnlyDeletesAfterLastRelease(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	cfg := testConfig("iPhone")

	udid, err := sm.Lease(1, false, cfg)
	require.NoError(t, err)
	_, err = sm.Lease(2, false, cfg)
	require.NoError(t, err)

	require.NoError(t, sm.Release(1))
	assert.Empty(t, control.deleteCalls, "device is still referenced by PID 2")

	require.NoError(t, sm.Release(2))
	assert.Equal(t, []SimulatorUDID{udid}, control.deleteCalls, "device should be deleted once unreferenced")
}

func TestPendingDeletion_Resurrection(t *testing.T) {
	control := newFakeSimulatorControl()
	// A long idle timeout means the background deletion task has no chance to
	// fire before this test's synchronous re-lease below.
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	udid1, err := sm.Lease(1, false, cfg)
	require.NoError(t, err)
	require.NoError(t, sm.Release(1))
	assert.Empty(t, control.deleteCalls, "device should be pending deletion, not deleted yet")

	udid2, err := sm.Lease(2, false, cfg)
	require.NoError(t, err)

	assert.Equal(t, udid1, udid2, "a new lease should resurrect the pending-deletion device")
	assert.Len(t, control.cloneCalls, 1, "resurrection must not create a second device")
}

func TestReuseSimulator_InvalidDeviceIsRecreated(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	udid1, err := sm.Lease(1, false, cfg)
	require.NoError(t, err)
	require.NoError(t, sm.Release(1))

	// Simulate the device having gone corrupt/invalid in the interim.
	control.ensureBootedErrs[udid1] = &ProcessError{ExitCode: 148}

	udid2, err := sm.Lease(2, false, cfg)
	require.NoError(t, err)

	assert.NotEqual(t, udid1, udid2, "an invalid device must be replaced, not reused")
	assert.Contains(t, control.deleteCalls, udid1, "the corrupt device should have been deleted")
	assert.Len(t, control.cloneCalls, 2, "one original clone plus one replacement")
}

func TestLease_ConcurrentNonExclusiveRequests_ShareOneInFlightClone(t *testing.T) {
	control := newFakeSimulatorControl()
	control.cloneGate = make(chan struct{})
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	type leaseResult struct {
		udid SimulatorUDID
		err  error
	}
	results := make(chan leaseResult, 2)

	go func() {
		udid, err := sm.Lease(1, false, cfg)
		results <- leaseResult{udid, err}
	}()

	// Wait for the first request to actually start cloning (and block on the
	// gate) before issuing the second, so this deterministically exercises
	// the "join an in-flight clone" path rather than racing two fresh clones.
	require.Eventually(t, func() bool {
		control.mu.Lock()
		defer control.mu.Unlock()
		return len(control.cloneCalls) == 1
	}, 2*time.Second, 5*time.Millisecond)

	go func() {
		udid, err := sm.Lease(2, false, cfg)
		results <- leaseResult{udid, err}
	}()

	// Give the second request a moment to reach the shared pendingCreation
	// slot before unblocking the clone, then let it complete.
	time.Sleep(50 * time.Millisecond)
	close(control.cloneGate)

	first := <-results
	second := <-results
	require.NoError(t, first.err)
	require.NoError(t, second.err)

	assert.Equal(t, first.udid, second.udid, "both leasers should get the same, singly-cloned device")
	assert.Len(t, control.cloneCalls, 1, "only one clone should ever have been started")
}

func TestLease_LeaserAlreadyExited(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, true, nil)
	deadPID := spawnDeadPID(t)

	_, err := sm.Lease(deadPID, false, testConfig("iPhone"))

	assert.Equal(t, ErrLeaserExited, err)
	assert.Empty(t, control.cloneCalls, "must not provision a device for a leaser that's already gone")
}

func TestDeleteOnPIDExit_AutoReleasesWhenProcessDies(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, true, nil)
	cmd, pid := spawnLiveProcess(t)

	udid, err := sm.Lease(pid, true, testConfig("iPhone"))
	require.NoError(t, err)

	require.NoError(t, cmd.Process.Kill())
	_ = cmd.Wait()

	require.Eventually(t, func() bool {
		return sm.Release(pid) == ErrNoLease
	}, 3*time.Second, 50*time.Millisecond, "manager should auto-release once the leasing process exits")

	assert.Contains(t, control.deleteCalls, udid)
}

func TestLease_FailsAssertionWhenMoreThanOneRunningSimulatorShareTheSlot(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	// Simulate the exact failure mode the assertion exists to catch: two real
	// booted devices ended up sharing what should be one slot's name.
	name := cfg.CloneDeviceName(0)
	control.runningOverride[name] = []SimCtlDevice{
		{Name: name, UDID: "udid-a", State: "Booted"},
		{Name: name, UDID: "udid-b", State: "Booted"},
	}

	_, err := sm.Lease(1, false, cfg)

	require.Error(t, err)
	assert.Contains(t, err.Error(), "assertion failed")
	assert.Contains(t, err.Error(), "udid-a")
	assert.Contains(t, err.Error(), "udid-b")
	assert.Equal(t, ErrNoLease, sm.Release(1), "a lease that failed the assertion must not have been recorded")
	assert.Equal(t, 0, sm.LiveLeaseCount())
}

func TestLease_SucceedsWhenAtMostOneRunningSimulatorForTheSlot(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 60, 60, false, nil)
	cfg := testConfig("iPhone")

	name := cfg.CloneDeviceName(0)
	control.runningOverride[name] = []SimCtlDevice{
		{Name: name, UDID: "udid-a", State: "Booted"},
	}

	udid, err := sm.Lease(1, false, cfg)

	require.NoError(t, err)
	assert.NotEmpty(t, udid)
}

func TestLease_IgnoresRunningSimulatorsListErrorRatherThanFailingTheLease(t *testing.T) {
	control := &erroringRunningSimulatorsControl{fakeSimulatorControl: newFakeSimulatorControl()}
	sm := newTestManager(control, 60, 60, false, nil)

	udid, err := sm.Lease(1, false, testConfig("iPhone"))

	require.NoError(t, err, "a failure to run the diagnostic check itself must not fail the lease")
	assert.NotEmpty(t, udid)
}

func TestLiveLeaseCount(t *testing.T) {
	control := newFakeSimulatorControl()
	// deleteOnPIDExit disabled so a lease for an already-dead PID isn't
	// rejected or auto-released -- this test wants both a live and a dead
	// lease to coexist in order to prove LiveLeaseCount filters correctly.
	sm := newTestManager(control, 60, 60, false, nil)

	_, livePID := spawnLiveProcess(t)
	deadPID := spawnDeadPID(t)

	_, err := sm.Lease(livePID, true, testConfig("iPhone-live"))
	require.NoError(t, err)
	_, err = sm.Lease(deadPID, true, testConfig("iPhone-dead"))
	require.NoError(t, err)

	assert.Equal(t, 1, sm.LiveLeaseCount())
}

func TestRestoreLeases_AdoptsRunningLease_DropsExitedLease(t *testing.T) {
	control := newFakeSimulatorControl()
	deadPID := spawnDeadPID(t)
	// The test process itself is guaranteed to still be running.
	livePID := int32(os.Getpid())

	store := &fakeLeaseStore{
		loaded: []PersistedLease{
			{
				PID:       livePID,
				UDID:      "udid-running",
				Config:    testConfig("running"),
				Exclusive: true,
				SlotIndex: 0,
			},
			{
				PID:       deadPID,
				UDID:      "udid-exited",
				Config:    testConfig("exited"),
				Exclusive: true,
				SlotIndex: 0,
			},
		},
	}

	sm := newTestManager(control, 60, 60, false, store)
	sm.RestoreLeases()

	assert.NoError(t, sm.Release(livePID), "the lease for a still-running process should have been adopted")
	assert.Equal(t, ErrNoLease, sm.Release(deadPID), "the lease for an exited process should have been dropped")
}

func TestRestoreLeases_ConflictingExclusiveLeases_KeepsFirstOnly(t *testing.T) {
	control := newFakeSimulatorControl()
	_, pid1 := spawnLiveProcess(t)
	_, pid2 := spawnLiveProcess(t)

	cfg := testConfig("iPhone")
	store := &fakeLeaseStore{
		loaded: []PersistedLease{
			{PID: pid1, UDID: "udid-shared", Config: cfg, Exclusive: true, SlotIndex: 0},
			{PID: pid2, UDID: "udid-shared", Config: cfg, Exclusive: true, SlotIndex: 0},
		},
	}

	sm := newTestManager(control, 60, 60, false, store)
	sm.RestoreLeases()

	firstErr := sm.Release(pid1)
	secondErr := sm.Release(pid2)

	// Restoration walks the persisted list in order, so the first entry wins
	// and the second is rejected as conflicting -- exactly one adopted.
	adopted := 0
	if firstErr == nil {
		adopted++
	}
	if secondErr == nil {
		adopted++
	}
	assert.Equal(t, 1, adopted, "exactly one of the two conflicting leases should have been adopted")
}
