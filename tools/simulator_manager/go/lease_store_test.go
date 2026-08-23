package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFileLeaseStore_LoadNonexistentFile(t *testing.T) {
	store := NewFileLeaseStore(filepath.Join(t.TempDir(), "does-not-exist.json"))
	assert.Nil(t, store.Load())
}

func TestFileLeaseStore_SaveAndLoadRoundTrip(t *testing.T) {
	path := filepath.Join(t.TempDir(), "leases.json")
	store := NewFileLeaseStore(path)

	startTime := uint64(123)
	leases := []PersistedLease{
		{
			PID:             42,
			LeaserStartTime: &startTime,
			UDID:            "udid-1",
			Config:          SimulatorConfig{DeviceType: "iPhone", OS: "iOS", Version: "17.0"},
			Exclusive:       true,
			SlotIndex:       0,
		},
		{
			PID:       43,
			UDID:      "udid-2",
			Config:    SimulatorConfig{DeviceType: "iPad", OS: "iOS", Version: "17.0"},
			Exclusive: false,
			SlotIndex: 1,
		},
	}

	store.Save(leases)

	loaded := store.Load()
	require.Equal(t, leases, loaded)
}

func TestFileLeaseStore_SaveIsAtomic(t *testing.T) {
	path := filepath.Join(t.TempDir(), "leases.json")
	store := NewFileLeaseStore(path)

	store.Save([]PersistedLease{{PID: 1, UDID: "udid-1"}})
	store.Save([]PersistedLease{{PID: 2, UDID: "udid-2"}})

	// The temp file used for the atomic rename should never be left behind.
	_, err := os.Stat(path + ".tmp")
	assert.True(t, os.IsNotExist(err))

	loaded := store.Load()
	require.Len(t, loaded, 1)
	assert.Equal(t, int32(2), loaded[0].PID)
}

func TestFileLeaseStore_LoadCorruptFileReturnsNilInsteadOfCrashing(t *testing.T) {
	path := filepath.Join(t.TempDir(), "leases.json")
	require.NoError(t, os.WriteFile(path, []byte("not valid json"), 0644))

	store := NewFileLeaseStore(path)
	assert.Nil(t, store.Load())
}

func TestProcessStartTime_CurrentProcessIsStable(t *testing.T) {
	pid := int32(os.Getpid())

	first := processStartTime(pid)
	require.NotNil(t, first, "should be able to read the current process's own start time")

	second := processStartTime(pid)
	require.NotNil(t, second)

	assert.Equal(t, *first, *second, "the start time of a still-running process must not change between calls")
}

func TestProcessStartTime_ExitedProcessReturnsNil(t *testing.T) {
	assert.Nil(t, processStartTime(spawnDeadPID(t)))
}
