package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSimulatorConfig_Naming(t *testing.T) {
	cfg := SimulatorConfig{DeviceType: "iPhone15,3", OS: "iOS", Version: "17.4"}

	assert.Equal(t, "iPhone15,3 (iOS 17.4)", cfg.String())
	assert.Equal(t, "EXAMPLE_BAZEL_BASE_iPhone15,3_17.4", cfg.BaseDeviceName())
	assert.Equal(t, "EXAMPLE_BAZEL_CLONE_iPhone15,3_17.4_0", cfg.CloneDeviceName(0))
	assert.Equal(t, "EXAMPLE_BAZEL_CLONE_iPhone15,3_17.4_3", cfg.CloneDeviceName(3))
	assert.Equal(t, "com.apple.CoreSimulator.SimRuntime.iOS-17-4", cfg.RuntimeIdentifier())
}

func TestProcessError_Error(t *testing.T) {
	withoutContext := &ProcessError{Command: "xcrun simctl delete X", ExitCode: 1, StdOut: "out", StdErr: "err"}
	assert.Equal(t, "\"xcrun simctl delete X\" failed with exit code 1:\nouterr", withoutContext.Error())

	withContext := &ProcessError{Command: "xcrun simctl delete X", Context: "reaper", ExitCode: 2, StdOut: "", StdErr: "boom"}
	assert.Equal(t, "\"xcrun simctl delete X\" (reaper) failed with exit code 2:\nboom", withContext.Error())
}

func TestSubprocess_CapturesStdout(t *testing.T) {
	out, err := subprocess("/bin/echo", []string{"hello", "world"}, nil, "")
	assert := assert.New(t)
	assert.NoError(err)
	assert.Equal("hello world\n", out)
}

func TestSubprocess_FailureReturnsProcessErrorWithExitCode(t *testing.T) {
	_, err := subprocess("/usr/bin/false", nil, nil, "test-context")

	pe, ok := err.(*ProcessError)
	assert := assert.New(t)
	assert.True(ok, "expected a *ProcessError, got %T", err)
	assert.Equal(1, pe.ExitCode)
	assert.Equal("test-context", pe.Context)
}

func TestSubprocess_PassesEnvironment(t *testing.T) {
	out, err := subprocess("/bin/sh", []string{"-c", "echo $SIMULATOR_UDID"}, map[string]string{"SIMULATOR_UDID": "udid-123"}, "")
	assert := assert.New(t)
	assert.NoError(err)
	assert.Equal("udid-123\n", out)
}
