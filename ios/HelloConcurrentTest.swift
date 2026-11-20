import XCTest

/// Checks that concurrent tests each lease their own simulator.
///
/// Unlike HelloAppConcurrentUITest this has no test host, so rules_apple runs it
/// via `simctl spawn` rather than `xcodebuild`.
///
/// Several targets share this source; each logs its UDID, and no two should
/// match. The sleep holds the lease long enough for the runs to actually overlap.
///
/// `SIMULATOR_MANAGER_HOLD_SECS` lengthens that hold, for experiments that need a
/// lease to still be live while something else happens on the worker -- a daemon
/// upgrade, say. Keep it under the target's timeout.
class HelloConcurrentTest: XCTestCase {
    func testHoldsItsOwnSimulator() {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
        print("CONCURRENT_UNIT_TEST_SIMULATOR_UDID=\(udid)")
        XCTAssertEqual(1 + 1, 2)

        let hold = ProcessInfo.processInfo.environment["SIMULATOR_MANAGER_HOLD_SECS"]
            .flatMap(Double.init) ?? 20
        // Bracketed by prints so a log shows whether the lease was still held when
        // whatever else was under test happened.
        print("CONCURRENT_UNIT_TEST_HOLDING_FOR=\(hold)")
        fflush(stdout)
        Thread.sleep(forTimeInterval: hold)
        print("CONCURRENT_UNIT_TEST_HOLD_DONE")
    }
}
