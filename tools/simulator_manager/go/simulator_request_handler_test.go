package main

import (
	"net/http"
	"net/url"
	"os"
	"strconv"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func newTestRequestHandler() (*SimulatorRequestHandler, *fakeSimulatorControl) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	return NewSimulatorRequestHandler(sm), control
}

func TestHandleRequest_UnsupportedMethod(t *testing.T) {
	h, _ := newTestRequestHandler()

	resp := h.HandleRequest(http.MethodGet, "/simulator/1", url.Values{})

	assert.Equal(t, http.StatusMethodNotAllowed, resp.Status)
}

func TestHandlePost_MissingPID(t *testing.T) {
	h, _ := newTestRequestHandler()

	resp := h.HandleRequest(http.MethodPost, "/simulator/", url.Values{})

	assert.Equal(t, http.StatusBadRequest, resp.Status)
	assert.Contains(t, resp.Message, "leaser PID")
}

func TestHandlePost_NonIntegerPID(t *testing.T) {
	h, _ := newTestRequestHandler()

	resp := h.HandleRequest(http.MethodPost, "/simulator/not-a-pid", url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"}})

	assert.Equal(t, http.StatusBadRequest, resp.Status)
}

func TestHandlePost_MissingQueryParams(t *testing.T) {
	h, _ := newTestRequestHandler()

	cases := []struct {
		name   string
		params url.Values
	}{
		{"missing exclusive", url.Values{"deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"}}},
		{"missing deviceType", url.Values{"exclusive": {"1"}, "os": {"iOS"}, "version": {"17.0"}}},
		{"missing os", url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "version": {"17.0"}}},
		{"missing version", url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "os": {"iOS"}}},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			resp := h.HandleRequest(http.MethodPost, "/simulator/1", c.params)
			assert.Equal(t, http.StatusBadRequest, resp.Status)
		})
	}
}

func TestHandlePost_Success(t *testing.T) {
	h, control := newTestRequestHandler()

	resp := h.HandleRequest(http.MethodPost, "/simulator/1", url.Values{
		"exclusive":  {"1"},
		"deviceType": {"iPhone"},
		"os":         {"iOS"},
		"version":    {"17.0"},
	})

	require.Equal(t, http.StatusCreated, resp.Status)
	assert.Equal(t, control.cloneCalls[0], "EXAMPLE_BAZEL_CLONE_iPhone_17.0_0")
	assert.NotEmpty(t, resp.Message, "response body should carry the leased UDID")
}

func TestHandlePost_NonExclusiveWhenNotSetTo1(t *testing.T) {
	h, control := newTestRequestHandler()

	// Anything other than exactly "1" for `exclusive` should be treated as
	// non-exclusive, per the query-param contract.
	_ = h.HandleRequest(http.MethodPost, "/simulator/1", url.Values{
		"exclusive": {"0"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"},
	})
	first := h.HandleRequest(http.MethodPost, "/simulator/2", url.Values{
		"exclusive": {"0"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"},
	})

	require.Equal(t, http.StatusCreated, first.Status)
	assert.Len(t, control.cloneCalls, 1, "both non-exclusive leases should share the same device")
}

func TestHandlePost_AlreadyLeased(t *testing.T) {
	h, _ := newTestRequestHandler()
	params := url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"}}

	first := h.HandleRequest(http.MethodPost, "/simulator/1", params)
	require.Equal(t, http.StatusCreated, first.Status)

	second := h.HandleRequest(http.MethodPost, "/simulator/1", params)
	assert.Equal(t, http.StatusBadRequest, second.Status)
	assert.Contains(t, second.Message, "already leased")
}

func TestHandleDelete_MissingPID(t *testing.T) {
	h, _ := newTestRequestHandler()

	resp := h.HandleRequest(http.MethodDelete, "/simulator/", url.Values{})

	assert.Equal(t, http.StatusBadRequest, resp.Status)
}

func TestHandleDelete_NoLease(t *testing.T) {
	h, _ := newTestRequestHandler()

	resp := h.HandleRequest(http.MethodDelete, "/simulator/1", url.Values{})

	assert.Equal(t, http.StatusNotFound, resp.Status)
	assert.Contains(t, resp.Message, "doesn't have a simulator leased")
}

func TestHandleDelete_Success(t *testing.T) {
	h, _ := newTestRequestHandler()
	params := url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"}}

	require.Equal(t, http.StatusCreated, h.HandleRequest(http.MethodPost, "/simulator/1", params).Status)

	resp := h.HandleRequest(http.MethodDelete, "/simulator/1", url.Values{})
	assert.Equal(t, http.StatusOK, resp.Status)
}

func TestLiveLeaseCount_Passthrough(t *testing.T) {
	h, _ := newTestRequestHandler()
	params := url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"}}

	assert.Equal(t, 0, h.LiveLeaseCount())

	// This test process's own PID is guaranteed to be running.
	pid := strconv.Itoa(os.Getpid())
	require.Equal(t, http.StatusCreated, h.HandleRequest(http.MethodPost, "/simulator/"+pid, params).Status)

	assert.Equal(t, 1, h.LiveLeaseCount())
}
