package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

type arrayFlags []string

func (a *arrayFlags) String() string {
	return strings.Join(*a, ", ")
}

func (a *arrayFlags) Set(value string) error {
	*a = append(*a, value)
	return nil
}

func main() {
	var version string
	var pidPath string
	var unixSocketPath string
	var deleteRecentlyUsedIdleAfter uint
	var deleteIdleAfter uint
	var recentlyUsedCapacity int
	var startupProcesses arrayFlags
	var postBoot string
	var leasePath string

	flag.StringVar(&version, "version", "", "Version of the simulator manager")
	flag.StringVar(&pidPath, "pid-path", "", "Path to where the pid should be written")
	flag.StringVar(&unixSocketPath, "unix-socket-path", "", "Path to where the unix domain socket should be created")
	flag.UintVar(&deleteRecentlyUsedIdleAfter, "delete-recently-used-idle-after", 0, "Number of seconds to wait before deleting a recently used idle simulator")
	flag.UintVar(&deleteIdleAfter, "delete-idle-after", 0, "Number of seconds to wait before deleting a non-recently used idle simulator")
	flag.IntVar(&recentlyUsedCapacity, "recently-used-capacity", 1, "The number of simulators to keep in the recently used list")
	flag.Var(&startupProcesses, "startup-process", "The path to a startup process that will be run when the simulator manager is started")
	flag.StringVar(&postBoot, "post-boot", "", "Path to an executable that will run after a simulator clone is booted")
	flag.StringVar(&leasePath, "lease-path", "", "Path to a file where leases are mirrored")

	flag.Parse()

	if version == "" {
		fmt.Fprintln(os.Stderr, "Error: --version is required")
		flag.Usage()
		os.Exit(1)
	}

	if pidPath == "" {
		fmt.Fprintln(os.Stderr, "Error: --pid-path is required")
		flag.Usage()
		os.Exit(1)
	}

	if unixSocketPath == "" {
		fmt.Fprintln(os.Stderr, "Error: --unix-socket-path is required")
		flag.Usage()
		os.Exit(1)
	}

	if recentlyUsedCapacity <= 0 {
		fmt.Fprintln(os.Stderr, "Error: --recently-used-capacity must be greater than 0")
		os.Exit(1)
	}

	seen := make(map[string]bool)
	for _, proc := range startupProcesses {
		if seen[proc] {
			fmt.Fprintf(os.Stderr, "Error: --startup-process must be unique, found duplicate: %s\n", proc)
			os.Exit(1)
		}
		seen[proc] = true
	}

	var leaseStore LeaseStore
	if leasePath != "" {
		leaseStore = NewFileLeaseStore(leasePath)
	}

	var postBootPtr *string
	if postBoot != "" {
		postBootPtr = &postBoot
	}

	simulatorManager := NewSimulatorManager(
		NewRealSimulatorControl(),
		uint16(deleteRecentlyUsedIdleAfter),
		uint16(deleteIdleAfter),
		recentlyUsedCapacity,
		true, // deleteOnPIDExit
		startupProcesses,
		postBootPtr,
		leaseStore,
	)

	simulatorManager.RestoreLeases()

	if err := simulatorManager.StartChildProcesses(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start child processes: %v\n", err)
		os.Exit(1)
	}

	httpServer := NewHTTPServer(
		NewSimulatorRequestHandler(simulatorManager),
		version,
	)

	if err := httpServer.Run(pidPath, unixSocketPath); err != nil {
		fmt.Fprintf(os.Stderr, "Server error: %v\n", err)
		os.Exit(1)
	}
}
