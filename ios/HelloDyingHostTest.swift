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
///  * `runner` -- SIGKILL to the rules_apple runner script, i.e. the process that
///    actually holds the lease. `signal` and `exit` only kill the test host,
///    which the script outlives, so the script still releases its own live lease
///    successfully. This mode targets the lease holder itself.
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
        default:
            break
        }
    }
}
