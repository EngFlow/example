import Darwin
import XCTest

/// Kills its own test host mid-suite, to find out whether a dying test process is
/// enough to produce a "PID N doesn't have a simulator leased" warning.
///
/// The warning means the daemon had no lease for the PID that tried to release
/// one, which happens when the daemon already reclaimed the lease via its
/// leaser-exit listener. The open question is *whose* death triggers that: the
/// lease is keyed on the rules_apple runner script's PID
/// (`XCTESTRUN_RUNNER_PID`), and that script outlives the test host, so killing
/// the host may leave the lease untouched.
///
/// `SIMULATOR_MANAGER_DEATH_MODE` selects how to die.
///
///  * `signal` -- SIGKILL, matching "Test crashed with signal kill before
///    establishing connection".
///  * `exit` -- a zero exit, matching "The test runner exited with code 0 before
///    establishing connection".
///  * `memory` -- allocate and touch pages until the kernel's memory-pressure
///    killer reaps the process, standing in for a worker running several
///    simulators at once.
///  * `hang` -- sleep past the action's timeout, so the test is killed from
///    outside rather than dying on its own.
///
/// Unset means don't die, so the target is also a control.
class HelloDyingHostTest: XCTestCase {
    /// Named to sort before `testDies`: XCTest runs cases alphabetically, so this
    /// establishes that the suite was really running before the host went away.
    func testAaaRunsBeforeDying() {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
        print("DYING_HOST_SIMULATOR_UDID=\(udid)")
        print("DYING_HOST_PID=\(getpid())")
    }

    func testDies() {
        let mode = ProcessInfo.processInfo.environment["SIMULATOR_MANAGER_DEATH_MODE"] ?? ""
        print("DYING_HOST_DEATH_MODE=\(mode)")

        switch mode {
        case "signal":
            kill(getpid(), SIGKILL)
        case "exit":
            exit(0)
        case "memory":
            exhaustMemory()
        case "hang":
            // Longer than any timeout this target is given, so the kill comes from
            // the harness rather than from here.
            sleep(3600)
        default:
            break
        }
    }

    /// Allocates in chunks and writes to every page, so the pages are resident
    /// rather than merely reserved -- a lazily-mapped allocation does not trigger
    /// the memory-pressure killer.
    ///
    /// Prints progress so the log records how far it got: if the process is
    /// reaped, the last line is the high-water mark.
    private func exhaustMemory() {
        let chunkBytes = 64 * 1024 * 1024
        var chunks: [UnsafeMutableRawPointer] = []

        while true {
            guard let chunk = malloc(chunkBytes) else {
                print("DYING_HOST_MALLOC_FAILED_AT_MB=\(chunks.count * 64)")
                fflush(stdout)
                return
            }
            memset(chunk, 1, chunkBytes)
            chunks.append(chunk)
            print("DYING_HOST_RESIDENT_MB=\(chunks.count * 64)")
            fflush(stdout)
        }
    }
}
