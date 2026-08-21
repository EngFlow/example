import UIKit
import XCTest

class HelloLongRunningTest: XCTestCase {
    private static var totalSeconds: Double {
        let configured = ProcessInfo.processInfo.environment["LONG_RUNNING_TEST_SECONDS"]
        return configured.flatMap(Double.init) ?? 600
    }

    /// Several short cases instead of one long sleep, so the log shows when a run died
    /// rather than just that it did.
    private static let phases = 5

    func testPhase1() { runPhase(1) }
    func testPhase2() { runPhase(2) }
    func testPhase3() { runPhase(3) }
    func testPhase4() { runPhase(4) }
    func testPhase5() { runPhase(5) }

    /// Prints the UDID so a failed run can be matched up with the daemon's own log:
    ///
    ///     log show --info --predicate \
    ///       'subsystem == "com.example.tools.simulator_manager"' | grep <udid>
    override func setUp() {
        super.setUp()
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
        print("LONG_RUNNING_SIMULATOR_UDID=\(udid)")
    }

    /// Uses `phys_footprint` instead of `resident_size` because that is the number the OS
    /// looks at when it decides to kill something.
    private func footprintMiB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return -1 }
        return Double(info.phys_footprint) / 1_048_576
    }

    private func runPhase(_ phase: Int) {
        let budget = Self.totalSeconds / Double(Self.phases)
        let deadline = Date().addingTimeInterval(budget)
        var iterations = 0

        // The pid tells you whether memory grew or whether xcodebuild just restarted the
        // app and reset the count.
        let startFootprint = footprintMiB()
        print(String(
            format: "phase %d start pid=%d footprint=%.1f MiB",
            phase, getpid(), startFootprint
        ))

        // Draws real views instead of sleeping, because a sleeping test still passes on a
        // device that has half gone away.
        //
        // The pool is not needed to pass, but without it each phase peaks at ~653 MiB
        // instead of ~35 MiB, and these workers only have 16 GiB and no swap.
        //
        // Prints as it goes, because a phase that gets killed never reaches the summary
        // print at the end.
        var nextSample = Date().addingTimeInterval(15)
        while Date() < deadline {
            autoreleasepool {
                render(iteration: iterations)
            }
            iterations += 1

            if Date() >= nextSample {
                print(String(
                    format: "phase %d sample iter=%d footprint=%.1f MiB",
                    phase, iterations, footprintMiB()
                ))
                nextSample = Date().addingTimeInterval(15)
            }
        }

        let endFootprint = footprintMiB()
        print("phase \(phase) completed \(iterations) renders in \(budget)s")
        print(String(
            format: "phase %d end pid=%d footprint=%.1f MiB (delta %+.1f MiB)",
            phase, getpid(), endFootprint, endFootprint - startFootprint
        ))
        XCTAssertGreaterThan(iterations, 0, "phase \(phase) rendered nothing")
    }

    private func render(iteration: Int) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.backgroundColor = iteration.isMultiple(of: 2) ? .systemBlue : .systemRed

        let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
        label.text = "iteration \(iteration)"
        label.numberOfLines = 0
        view.addSubview(label)

        // Uses `drawHierarchy` because `view.layer.render(in:)` held on to ~2.45 MiB every
        // call, about 45 GiB a phase, until the OS killed the app.
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        XCTAssertGreaterThan(image.size.width, 0)
    }
}
