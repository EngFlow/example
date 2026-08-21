package main

import (
	"log/slog"
	"os"
)

var (
	logger                 = newLogger("manager")
	childProcessLogger     = newLogger("manager.child-process")
	httpServerLogger       = newLogger("server")
	accumulatedHTTPLogger  = newLogger("accumulated_http")
	simulatorControlLogger = newLogger("control")
	leaseStoreLogger       = newLogger("manager.lease-store")
)

func newLogger(category string) *slog.Logger {
	return slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})).With("subsystem", "com.example.tools.simulator_manager", "category", category)
}
