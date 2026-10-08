// App/SelfTest.swift
// Mosaic
//
// Debug builds only: `-MosaicSelfTest <bundle id>` runs every kind of move on that app's frontmost window
// against the real displays, checks where it landed, and writes a report to /tmp/mosaic-selftest.txt.

#if DEBUG
import AppKit

final class SelfTest {
    private let mover: WindowMover
    private let engine: ArrangementEngine
    private var lines: [String] = []
    private var failures = 0

    init(mover: WindowMover, engine: ArrangementEngine) {
        self.mover = mover
        self.engine = engine
    }

    func run(bundleID: String) async {
        log("Displays, left to right:")
        let displays = DisplayCatalog.current()
        for (index, display) in displays.enumerated() {
            log("  \(index): \(display.name) \(display.visibleFrame) key \(display.ref.key)")
        }
        guard WindowAccess.isTrusted else { return finish("FAIL: no Accessibility access") }
        guard let app = await waitForApp(bundleID), let window = await waitForWindow(of: app) else {
            return finish("FAIL: no window for \(bundleID)")
        }
        await testRegions(window, displays)
        await testWalking(window, displays)
        await testArrangement(window, app: app, bundleID: bundleID, displays: displays)
        finish(failures == 0 ? "PASS" : "FAIL: \(failures) checks")
    }

    private func testRegions(_ window: AXWindow, _ displays: [Display]) async {
        for (index, display) in displays.enumerated() {
            for region in [Region.leftHalf, .rightHalf, .topLeft, .bottomRight, .firstThird, .maximize, .center] {
                mover.snap(window, to: region, on: display)
                await settle()
                let expected = Geometry.frame(for: .region(region), in: display.visibleFrame, gap: Preferences.gap,
                                              current: window.frame)
                check("display \(index) \(region.title)", window.frame, expected)
            }
        }
    }

    private func testWalking(_ window: AXWindow, _ displays: [Display]) async {
        log("Walking right with Right Half from the leftmost display:")
        mover.snap(window, to: .leftHalf, on: displays[0])
        await settle()
        for step in 1...(displays.count * 2) {
            mover.step(window, to: .rightHalf)
            await settle()
            log("  step \(step): \(describe(window.frame, displays))")
        }
        log("Walking left with Left Half:")
        for step in 1...(displays.count * 2) {
            mover.step(window, to: .leftHalf)
            await settle()
            log("  step \(step): \(describe(window.frame, displays))")
        }

        log("Next display, three times:")
        for step in 1...displays.count {
            mover.move(window, displayOffset: 1)
            await settle()
            log("  step \(step): \(describe(window.frame, displays))")
        }
    }

    private func testArrangement(_ window: AXWindow, app: NSRunningApplication, bundleID: String,
                                 displays: [Display]) async {
        log("Capture and apply:")
        mover.snap(window, to: .rightHalf, on: displays[min(1, displays.count - 1)])
        await settle()
        let arrangement = ArrangementEngine.capture(named: "Self Test")
        guard let placement = arrangement.placements.first(where: { $0.bundleID == bundleID }) else {
            return failure("captured arrangement has no placement for \(bundleID)")
        }
        log("  captured display \(placement.display), \(placement.area.title)")
        let expected = window.frame ?? .zero
        mover.snap(window, to: .center, on: displays[0])
        await settle()
        engine.apply(arrangement)
        await settle()
        check("re-applied arrangement", window.frame, expected)
        log("  signature matches current displays: \(arrangement.displaySignature == DisplayCatalog.signature)")

        log("App opened after applying:")
        // Read before quitting; a terminated app no longer reports where it lives.
        let document = window.documentURL, appURL = app.bundleURL
        app.terminate()
        for _ in 0..<20 where !app.isTerminated { try? await Task.sleep(for: .milliseconds(250)) }
        engine.apply(arrangement)
        if let document, let appURL {
            do {
                _ = try await NSWorkspace.shared.open([document], withApplicationAt: appURL,
                                                      configuration: NSWorkspace.OpenConfiguration())
            } catch {
                log("  reopen failed: \(error.localizedDescription)")
            }
        }
        guard let relaunched = await waitForApp(bundleID, excluding: app.processIdentifier), let reopened = await waitForWindow(of: relaunched) else {
            return failure("app didn't reopen with a window")
        }
        // Placement retries every quarter second until the window shows up.
        try? await Task.sleep(for: .seconds(2))
        check("placed on launch", reopened.frame, expected)
    }

    // MARK: - Helpers

    /// `excluding` skips an instance that just quit; it lingers in the running list for a moment.
    private func waitForApp(_ bundleID: String, excluding pid: pid_t? = nil) async -> NSRunningApplication? {
        for _ in 0..<40 {
            let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if let app = apps.first(where: { $0.processIdentifier != pid && !$0.isTerminated }) { return app }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return nil
    }

    private func waitForWindow(of app: NSRunningApplication) async -> AXWindow? {
        for _ in 0..<40 {
            if let window = WindowAccess.windows(of: app.processIdentifier).first { return window }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return nil
    }

    private func settle() async {
        try? await Task.sleep(for: .milliseconds(350))
    }

    private func check(_ name: String, _ actual: CGRect?, _ expected: CGRect) {
        guard let actual else { return failure("\(name): window has no frame") }
        if RegionStep.isAt(actual, expected, tolerance: 4) {
            log("  ok   \(name)")
        } else {
            failure("\(name): got \(actual), expected \(expected)")
        }
    }

    private func describe(_ frame: CGRect?, _ displays: [Display]) -> String {
        guard let frame, let index = Geometry.bestMatch(for: frame, among: displays.map(\.visibleFrame)) else { return "?" }
        return "display \(index), \(Geometry.area(matching: frame, in: displays[index].visibleFrame).title)"
    }

    private func failure(_ message: String) {
        failures += 1
        log("  FAIL \(message)")
    }

    private func log(_ line: String) {
        lines.append(line)
    }

    private func finish(_ result: String) {
        log(result)
        try? (lines.joined(separator: "\n") + "\n").write(toFile: "/tmp/mosaic-selftest.txt", atomically: true, encoding: .utf8)
    }
}
#endif
