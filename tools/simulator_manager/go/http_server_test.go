package main

// These tests exercise HTTPServer's HTTP handler methods directly via
// net/http/httptest, bypassing Run(). Run() itself (unix socket setup, PID
// file management, OS signal handling) and handleShutdownRequest (which
// calls os.Exit) are integration-level, OS-facing plumbing that would
// require killing or replacing the test process itself to exercise safely,
// so they're intentionally left uncovered here.

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestHandleVersionRequest(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	server := NewHTTPServer(NewSimulatorRequestHandler(sm), "v1.2.3")

	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	rec := httptest.NewRecorder()

	server.handleVersionRequest(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "v1.2.3\n", rec.Body.String())
}

func TestHandleLeasesRequest(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	server := NewHTTPServer(NewSimulatorRequestHandler(sm), "v1")

	req := httptest.NewRequest(http.MethodGet, "/leases", nil)
	rec := httptest.NewRecorder()

	server.handleLeasesRequest(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "0\n", rec.Body.String())
}

func TestHandleSimulatorRequest_RoutesToHandler(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	server := NewHTTPServer(NewSimulatorRequestHandler(sm), "v1")

	params := url.Values{"exclusive": {"1"}, "deviceType": {"iPhone"}, "os": {"iOS"}, "version": {"17.0"}}
	req := httptest.NewRequest(http.MethodPost, "/simulator/1?"+params.Encode(), nil)
	rec := httptest.NewRecorder()

	server.handleSimulatorRequest(rec, req)

	require.Equal(t, http.StatusCreated, rec.Code)
	assert.NotEmpty(t, rec.Body.String())
}

func TestHandleSimulatorRequest_BadRequestSurfacesMessage(t *testing.T) {
	control := newFakeSimulatorControl()
	sm := newTestManager(control, 0, 0, false, nil)
	server := NewHTTPServer(NewSimulatorRequestHandler(sm), "v1")

	req := httptest.NewRequest(http.MethodDelete, "/simulator/1", nil)
	rec := httptest.NewRecorder()

	server.handleSimulatorRequest(rec, req)

	assert.Equal(t, http.StatusNotFound, rec.Code)
	assert.Contains(t, rec.Body.String(), "doesn't have a simulator leased")
}
