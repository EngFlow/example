import UIKit
import XCTest

class HelloLongRunningTest: XCTestCase {
    private static var totalSeconds: Double {
        let configured = ProcessInfo.processInfo.environment["LONG_RUNNING_TEST_SECONDS"]
        return configured.flatMap(Double.init) ?? 600
    }

    /// Split across cases rather than spent in one `sleep`, for two reasons: a
    /// device pulled away is noticed at a case boundary as well as mid-case, and a
    /// suite that reports progress makes it obvious from the log *when* it died
    /// rather than only that it did.
    private static let phases = 5

    func testPhase1() { runPhase(1) }
    func testPhase2() { runPhase(2) }
    func testPhase3() { runPhase(3) }
    func testPhase4() { runPhase(4) }
    func testPhase5() { runPhase(5) }

    /// Logged so a failing run can be correlated with the daemon's own log, which
    /// keys everything on the UDID:
    ///
    ///     log show --info --predicate \
    ///       'subsystem == "com.example.tools.simulator_manager"' | grep <udid>
    override func setUp() {
        super.setUp()
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
        print("LONG_RUNNING_SIMULATOR_UDID=\(udid)")
    }

    private func runPhase(_ phase: Int) {
        let budget = Self.totalSeconds / Double(Self.phases)
        let deadline = Date().addingTimeInterval(budget)
        var iterations = 0

        // Real UIKit work rather than an idle wait. A sleeping test can survive on a
        // device that is half torn down; rendering needs the UI stack to still be
        // there, which is the thing an early release takes away.
        while Date() < deadline {
            render(iteration: iterations)
            iterations += 1
        }

        print("phase \(phase) completed \(iterations) renders in \(budget)s")
        XCTAssertGreaterThan(iterations, 0, "phase \(phase) rendered nothing")
    }

    private func render(iteration: Int) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.backgroundColor = iteration.isMultiple(of: 2) ? .systemBlue : .systemRed

        let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
        label.text = "iteration \(iteration)"
        label.numberOfLines = 0
        view.addSubview(label)

        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
        XCTAssertGreaterThan(image.size.width, 0)
    }
}
