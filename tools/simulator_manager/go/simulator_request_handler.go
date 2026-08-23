package main

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
)

type SimulatorManagerResponse struct {
	Status  int
	Message string
}

type SimulatorRequestHandler struct {
	simulatorManager *SimulatorManager
}

func NewSimulatorRequestHandler(simulatorManager *SimulatorManager) *SimulatorRequestHandler {
	return &SimulatorRequestHandler{
		simulatorManager: simulatorManager,
	}
}

func (h *SimulatorRequestHandler) LiveLeaseCount() int {
	return h.simulatorManager.LiveLeaseCount()
}

func (h *SimulatorRequestHandler) HandleRequest(method string, path string, queryParams url.Values) SimulatorManagerResponse {
	pathComponents := strings.Split(strings.Trim(path, "/"), "/")
	if len(pathComponents) > 0 && pathComponents[0] == "simulator" {
		pathComponents = pathComponents[1:]
	}

	switch method {
	case http.MethodPost:
		return h.handlePost(pathComponents, queryParams)
	case http.MethodDelete:
		return h.handleDelete(pathComponents, queryParams)
	default:
		return SimulatorManagerResponse{
			Status:  http.StatusMethodNotAllowed,
			Message: fmt.Sprintf("Unsupported HTTP method: %s", method),
		}
	}
}

func (h *SimulatorRequestHandler) handlePost(pathComponents []string, queryParams url.Values) SimulatorManagerResponse {
	if len(pathComponents) < 1 || pathComponents[0] == "" {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Must specify <leaser PID>",
		}
	}

	leaser, err := strconv.ParseInt(pathComponents[0], 10, 32)
	if err != nil {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Leaser PID must be an integer",
		}
	}

	exclusiveStr := queryParams.Get("exclusive")
	if exclusiveStr == "" {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Must specify 'exclusive' query parameter",
		}
	}
	exclusive := exclusiveStr == "1"

	deviceType := queryParams.Get("deviceType")
	if deviceType == "" {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Must specify 'deviceType' query parameter",
		}
	}

	osParam := queryParams.Get("os")
	if osParam == "" {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Must specify 'os' query parameter",
		}
	}

	version := queryParams.Get("version")
	if version == "" {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Must specify 'version' query parameter",
		}
	}

	config := SimulatorConfig{
		DeviceType: deviceType,
		OS:         osParam,
		Version:    version,
	}

	udid, err := h.simulatorManager.Lease(int32(leaser), exclusive, config)
	if err != nil {
		if err == ErrLeaserExited {
			return SimulatorManagerResponse{
				Status:  http.StatusGone,
				Message: fmt.Sprintf("PID %d exited before its simulator was provisioned", leaser),
			}
		}

		if sme, ok := err.(*SimulatorManagerError); ok && sme.kind == "alreadyLeased" {
			return SimulatorManagerResponse{
				Status:  http.StatusBadRequest,
				Message: fmt.Sprintf("PID %d has already leased another simulator: %s", leaser, sme.udid),
			}
		}

		return SimulatorManagerResponse{
			Status:  http.StatusInternalServerError,
			Message: fmt.Sprintf("Internal server error: %v", err),
		}
	}

	return SimulatorManagerResponse{
		Status:  http.StatusCreated,
		Message: udid,
	}
}

func (h *SimulatorRequestHandler) handleDelete(pathComponents []string, queryParams url.Values) SimulatorManagerResponse {
	if len(pathComponents) < 1 || pathComponents[0] == "" {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Must specify <leaser PID>",
		}
	}

	leaser, err := strconv.ParseInt(pathComponents[0], 10, 32)
	if err != nil {
		return SimulatorManagerResponse{
			Status:  http.StatusBadRequest,
			Message: "Leaser PID must be an integer",
		}
	}

	if err := h.simulatorManager.Release(int32(leaser)); err != nil {
		if err == ErrNoLease {
			return SimulatorManagerResponse{
				Status:  http.StatusNotFound,
				Message: fmt.Sprintf("PID %d doesn't have a simulator leased", leaser),
			}
		}

		return SimulatorManagerResponse{
			Status:  http.StatusInternalServerError,
			Message: fmt.Sprintf("Internal server error: %v", err),
		}
	}

	return SimulatorManagerResponse{
		Status:  http.StatusOK,
		Message: "Success",
	}
}
