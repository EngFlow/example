import UIKit
import XCTest

/// The distinguishing features, versus HelloConcurrentTest:
///
///  * it has a test host, so rules_apple drives it with `xcodebuild` and a
///    `-destination id=` rather than `simctl spawn`. `xcodebuild` installs the
///    host onto the device, which is the step that reports `No matching device`
///    when a device is removed underneath it.
///  * it renders views, so it needs a booted UI stack rather than just a process
///    to run in. A test host that dies mid-render produces the "Restarting after
///    unexpected exit, crash, or test timeout" line.
///
/// Many small cases rather than one long sleep: the failures this is meant to
/// provoke land between cases -- on install, or on a device pulled out from under
/// a suite that is partway through -- so the suite needs many opportunities to be
/// interrupted.
class HelloHostedSnapshotTest: XCTestCase {
    func testLogsItsDevice() {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "unknown"
        print("HOSTED_SNAPSHOT_SIMULATOR_UDID=\(udid)")
    }

    /// Renders a view hierarchy repeatedly, approximating snapshot work: enough
    /// UIKit and memory traffic per case to make contention on a shared device
    /// observable, without asserting on images we would then have to record.
    func testRendersRepeatedly() {
        for iteration in 0 ..< 40 {
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

    func testPresentsViewControllers() {
        for _ in 0 ..< 10 {
            let controller = UIViewController()
            controller.view.backgroundColor = .white
            let child = UIViewController()
            controller.addChild(child)
            controller.view.addSubview(child.view)
            child.didMove(toParent: controller)
            XCTAssertNotNil(controller.view)
        }
    }
}
