package main

import (
	"encoding/json"
	"os"

	"golang.org/x/sys/unix"
)

type SimulatorUDID = string

// PersistedLease is a lease, in the form it takes on disk.
//
// Holds everything needed to rebuild the daemon's in-memory bookkeeping for one
// lease: which device, under which configuration, in which slot, and whether it
// was owned exclusively. Nothing here has to be re-derived by asking simctl.
type PersistedLease struct {
	PID             int32           `json:"pid"`
	LeaserStartTime *uint64         `json:"leaserStartTime,omitempty"`
	UDID            SimulatorUDID   `json:"udid"`
	Config          SimulatorConfig `json:"config"`
	Exclusive       bool            `json:"exclusive"`
	SlotIndex       int             `json:"slotIndex"`
}

// LeaseStore is where the daemon keeps its leases so a successor can pick them up.
type LeaseStore interface {
	// Save replaces the stored set with leases. Failures are logged, not thrown:
	// losing persistence degrades a restart, but failing the lease that triggered
	// the write would break a test that is otherwise fine.
	Save(leases []PersistedLease)

	// Load returns the stored set, or empty if there is nothing readable to restore.
	Load() []PersistedLease
}

// FileLeaseStore is a LeaseStore backed by a JSON file.
//
// Written atomically, so a reader never sees a half-written set and a crash
// mid-write leaves the previous contents intact. Combined with writing on every
// change, this means the file is always current -- there is no flush-on-shutdown
// step for a kill -9 to skip.
type FileLeaseStore struct {
	path string
}

func NewFileLeaseStore(path string) *FileLeaseStore {
	return &FileLeaseStore{path: path}
}

func (f *FileLeaseStore) Save(leases []PersistedLease) {
	data, err := json.MarshalIndent(leases, "", "  ")
	if err != nil {
		leaseStoreLogger.Error("Failed to marshal leases", "error", err, "count", len(leases), "path", f.path)
		return
	}

	// Write atomically using a temp file and rename
	tmpPath := f.path + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		leaseStoreLogger.Error("Failed to write leases", "error", err, "count", len(leases), "path", f.path)
		return
	}

	if err := os.Rename(tmpPath, f.path); err != nil {
		leaseStoreLogger.Error("Failed to rename leases file", "error", err, "count", len(leases), "path", f.path)
		return
	}
}

func (f *FileLeaseStore) Load() []PersistedLease {
	if _, err := os.Stat(f.path); os.IsNotExist(err) {
		return nil
	}

	data, err := os.ReadFile(f.path)
	if err != nil {
		leaseStoreLogger.Error("Failed to read leases; continuing with none", "error", err, "path", f.path)
		return nil
	}

	var leases []PersistedLease
	if err := json.Unmarshal(data, &leases); err != nil {
		leaseStoreLogger.Error("Failed to decode leases; continuing with none", "error", err, "path", f.path)
		return nil
	}

	return leases
}

// processStartTime returns when pid started, in microseconds since the epoch, or nil if it cannot be
// determined (typically because the process is gone).
//
// A PID alone does not identify a process across a daemon restart: PIDs are
// recycled, so a lease for a dead PID could otherwise be restored onto whatever
// unrelated process now holds that number, tying up a device until it exits.
// Start time distinguishes them -- the kernel assigns it at fork, so a recycled
// PID has a different one.
func processStartTime(pid int32) *uint64 {
	info, err := unix.SysctlKinfoProc("kern.proc.pid", int(pid))
	if err != nil {
		return nil
	}

	startTime := uint64(info.Proc.P_starttime.Sec)*1_000_000 + uint64(info.Proc.P_starttime.Usec)
	return &startTime
}
