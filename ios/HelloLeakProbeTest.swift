import UIKit
import XCTest

/// Throwaway test that found what was holding on to memory in `HelloLongRunningTest` by
/// giving each case one suspect, and can be deleted now.
///
/// 1000 iterations is enough to see a 2.5 MiB-per-render problem but not a 0.037 MiB one,
/// which is why the pool looked pointless here but mattered over a full phase.
///
///     bazel test --config=ios --config=opal --config=remote_macos_arm64 \
///       --test_env=EXAMPLE_CI_STAGING_VERSION=1 --nocache_test_results \
///       --test_output=streamed //ios:HelloLeakProbeTest
class HelloLeakProbeTest: XCTestCase {
    private static let iterations = 1000

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

    /// Reports MiB per iteration rather than a total, and makes the pool optional so it can
    /// be tested too.
    private func measure(_ label: String, pooled: Bool = true, _ body: (Int) -> Void) {
        let before = footprintMiB()
        for i in 0 ..< Self.iterations {
            if pooled {
                autoreleasepool { body(i) }
            } else {
                body(i)
            }
        }
        let after = footprintMiB()
        let delta = after - before
        print(String(
            format: "LEAKPROBE %-28s iters=%d before=%.1f after=%.1f delta=%+.1f MiB perIter=%.4f MiB",
            (label as NSString).utf8String!, Self.iterations, before, after, delta,
            delta / Double(Self.iterations)
        ))
    }

    /// The original loop, copied as-is, to give the cases below something to compare
    /// against.
    func test1Baseline() {
        measure("baseline") { i in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            view.backgroundColor = i.isMultiple(of: 2) ? .systemBlue : .systemRed
            let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
            label.text = "iteration \(i)"
            label.numberOfLines = 0
            view.addSubview(label)
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            let image = renderer.image { context in
                view.layer.render(in: context.cgContext)
            }
            XCTAssertGreaterThan(image.size.width, 0)
        }
    }

    /// Builds the views but never draws them, so growth here would point at the views
    /// rather than the drawing.
    func test2ViewTreeOnly() {
        measure("view-tree-only") { i in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            view.backgroundColor = i.isMultiple(of: 2) ? .systemBlue : .systemRed
            let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
            label.text = "iteration \(i)"
            label.numberOfLines = 0
            view.addSubview(label)
            XCTAssertEqual(view.subviews.count, 1)
        }
    }

    /// Draws with no views at all, to see whether the renderer on its own is the problem.
    func test3RendererOnly() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        measure("renderer-only-fresh") { _ in
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { context in
                context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
                context.cgContext.fill(bounds)
            }
            XCTAssertGreaterThan(image.size.width, 0)
        }
    }

    /// Like `test3` but reuses one renderer, which would blame making a new one each time
    /// if only `test3` grew.
    func test4RendererReused() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        measure("renderer-reused") { _ in
            let image = renderer.image { context in
                context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
                context.cgContext.fill(bounds)
            }
            XCTAssertGreaterThan(image.size.width, 0)
        }
    }

    /// The original loop with one reused renderer, which looked like the fix until it grew
    /// just as fast as the baseline.
    func test5ViewTreeRendererReused() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        measure("view-tree+reused-renderer") { i in
            let view = UIView(frame: bounds)
            view.backgroundColor = i.isMultiple(of: 2) ? .systemBlue : .systemRed
            let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
            label.text = "iteration \(i)"
            label.numberOfLines = 0
            view.addSubview(label)
            let image = renderer.image { context in
                view.layer.render(in: context.cgContext)
            }
            XCTAssertGreaterThan(image.size.width, 0)
        }
    }

    /// Changes only the drawing call, and came out flat, which is what pinned the problem
    /// on `layer.render(in:)`.
    func test6DrawHierarchyInsteadOfLayerRender() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        measure("drawHierarchy") { i in
            let view = UIView(frame: bounds)
            view.backgroundColor = i.isMultiple(of: 2) ? .systemBlue : .systemRed
            let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
            label.text = "iteration \(i)"
            label.numberOfLines = 0
            view.addSubview(label)
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { _ in
                view.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
            XCTAssertGreaterThan(image.size.width, 0)
        }
    }

    /// `test6` with the pool taken out, which looked flat here but used about 18 times the
    /// memory over a full phase.
    func test7DrawHierarchyWithoutPool() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        measure("drawHierarchy-NO-pool", pooled: false) { i in
            let view = UIView(frame: bounds)
            view.backgroundColor = i.isMultiple(of: 2) ? .systemBlue : .systemRed
            let label = UILabel(frame: view.bounds.insetBy(dx: 20, dy: 20))
            label.text = "iteration \(i)"
            label.numberOfLines = 0
            view.addSubview(label)
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { _ in
                view.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
            XCTAssertGreaterThan(image.size.width, 0)
        }
    }
}
