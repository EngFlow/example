package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
)

type HTTPServer struct {
	simulatorRequestHandler *SimulatorRequestHandler
	version                 string
}

func NewHTTPServer(simulatorRequestHandler *SimulatorRequestHandler, version string) *HTTPServer {
	return &HTTPServer{
		simulatorRequestHandler: simulatorRequestHandler,
		version:                 version,
	}
}

func (s *HTTPServer) Run(pidPath string, unixSocketPath string) error {
	if err := os.Remove(unixSocketPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove existing socket: %w", err)
	}

	if err := os.Remove(pidPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove existing PID file: %w", err)
	}

	pid := os.Getpid()
	if err := os.WriteFile(pidPath, []byte(strconv.Itoa(pid)), 0644); err != nil {
		return fmt.Errorf("failed to write PID file: %w", err)
	}

	listener, err := net.Listen("unix", unixSocketPath)
	if err != nil {
		return fmt.Errorf("failed to listen on unix socket: %w", err)
	}

	httpServerLogger.Info("Server running on UDS", "path", unixSocketPath)

	mux := http.NewServeMux()
	mux.HandleFunc("/simulator", s.handleSimulatorRequest)
	mux.HandleFunc("/simulator/", s.handleSimulatorRequest)
	mux.HandleFunc("/version", s.handleVersionRequest)
	mux.HandleFunc("/leases", s.handleLeasesRequest)
	mux.HandleFunc("/shutdown", s.handleShutdownRequest)

	server := &http.Server{Handler: mux}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		httpServerLogger.Info("Shutting down server")
		_ = server.Shutdown(context.Background())
	}()

	err = server.Serve(listener)
	if err != nil && err != http.ErrServerClosed {
		return err
	}

	httpServerLogger.Info("Server shut down")

	_ = os.Remove(unixSocketPath)
	_ = os.Remove(pidPath)

	return nil
}

func (s *HTTPServer) handleSimulatorRequest(w http.ResponseWriter, r *http.Request) {
	accumulatedHTTPLogger.Info("Received request", "method", r.Method, "path", r.URL.Path)

	response := s.simulatorRequestHandler.HandleRequest(r.Method, r.URL.Path, r.URL.Query())

	accumulatedHTTPLogger.Info("Sending response", "status", response.Status)

	w.WriteHeader(response.Status)
	fmt.Fprintf(w, "%s\n", response.Message)
}

func (s *HTTPServer) handleVersionRequest(w http.ResponseWriter, r *http.Request) {
	accumulatedHTTPLogger.Info("Received request", "method", r.Method, "path", r.URL.Path)
	accumulatedHTTPLogger.Info("Sending response", "status", http.StatusOK)

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s\n", s.version)
}

func (s *HTTPServer) handleLeasesRequest(w http.ResponseWriter, r *http.Request) {
	accumulatedHTTPLogger.Info("Received request", "method", r.Method, "path", r.URL.Path)

	count := s.simulatorRequestHandler.LiveLeaseCount()

	accumulatedHTTPLogger.Info("Sending response", "status", http.StatusOK)

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%d\n", count)
}

func (s *HTTPServer) handleShutdownRequest(w http.ResponseWriter, r *http.Request) {
	accumulatedHTTPLogger.Info("Received request", "method", r.Method, "path", r.URL.Path)

	httpServerLogger.Info("Shutdown request received")

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Server shutting down\n")

	go func() {
		os.Exit(0)
	}()
}
