// Arrangements/ArrangementEngine.swift
// Mosaic
//
// Applies arrangements: moves running apps' windows into place now, and others as soon as they open.

import AppKit
import Observation

@Observable
final class ArrangementEngine {
    /// The arrangement last applied. Apps opening later are placed by it.
    private(set) var active: Arrangement?

    @ObservationIgnored private let mover: WindowMover
    @ObservationIgnored private var launchObserver: NSObjectProtocol?

    init(mover: WindowMover) {
        self.mover = mover
    }

    func start() {
        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                if let app { self?.appLaunched(app) }
            }
        }
    }

    func apply(_ arrangement: Arrangement) {
        active = arrangement
        guard WindowAccess.isTrusted else { return }
        let displays = DisplayCatalog.resolve(arrangement.displays, in: DisplayCatalog.current())
        for placement in arrangement.placements {
            guard let app = Self.runningApp(placement.bundleID) else { continue }
            place(placement, of: app, displays: displays, attempts: 1)
        }
    }

    private func appLaunched(_ app: NSRunningApplication) {
        guard let active, WindowAccess.isTrusted,
              let placement = active.placements.first(where: { $0.bundleID == app.bundleIdentifier }) else { return }
        let displays = DisplayCatalog.resolve(active.displays, in: DisplayCatalog.current())
        // A freshly launched app takes a moment to open its first window.
        place(placement, of: app, displays: displays, attempts: 40)
    }

    /// Places the app's frontmost window, retrying every quarter second until it has one.
    private func place(_ placement: Placement, of app: NSRunningApplication, displays: [Display?], attempts: Int) {
        guard placement.display < displays.count, let display = displays[placement.display] else { return }
        if let window = WindowAccess.windows(of: app.processIdentifier).first {
            mover.place(window, in: placement.area, on: display)
            return
        }
        guard attempts > 1 else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            self?.place(placement, of: app, displays: displays, attempts: attempts - 1)
        }
    }

    static func runningApp(_ bundleID: String) -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
    }

    // MARK: - Capture

    /// The current layout: each regular app's frontmost window, on the display that holds most of it.
    static func capture(named name: String) -> Arrangement {
        let displays = DisplayCatalog.current()
        let ignored = Preferences.ignoredApps
        let ownPID = ProcessInfo.processInfo.processIdentifier
        var placements: [Placement] = []
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != ownPID && !$0.isHidden
        }
        for app in apps {
            guard let bundleID = app.bundleIdentifier, !ignored.contains(bundleID),
                  let frame = WindowAccess.windows(of: app.processIdentifier).first?.frame,
                  let index = Geometry.bestMatch(for: frame, among: displays.map(\.visibleFrame)) else { continue }
            placements.append(Placement(bundleID: bundleID, appName: app.localizedName ?? bundleID, display: index,
                                        area: Geometry.area(matching: frame, in: displays[index].visibleFrame)))
        }
        placements.sort { ($0.display, $0.appName) < ($1.display, $1.appName) }
        return Arrangement(name: name, displays: displays.map(\.ref), placements: placements)
    }
}
