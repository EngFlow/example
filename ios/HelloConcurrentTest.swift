import XCTest

/// Checks that concurrent tests each lease their own simulator.
///
/// Unlike HelloAppConcurrentUITest this has no test host, so rules_apple runs it
/// via `simctl spawn` rather than `xcodebuild`.
///
/// Several targets share this source; each logs its UDID, and no two should
/// match. The sleep holds the lease long enough for the runs to actually overlap.
class HelloConcurrentTest: XCTestCase {
    func testHoldsItsOwnSimulator() {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
        print("CONCURRENT_UNIT_TEST_SIMULATOR_UDID=\(udid)")
        XCTAssertEqual(1 + 1, 2)
        Thread.sleep(forTimeInterval: 20)
    }
}
