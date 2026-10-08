// Snapping/SnapMonitor.swift
// Mosaic
//
// Watches for windows being dragged by their title bar and snaps them when dropped at a screen edge.

import AppKit

final class SnapMonitor {
    private let mover: WindowMover
    private let preview = SnapPreview()
    private var monitors: [Any] = []

    private var window: AXWindow?
    private var startFrame: CGRect?
    private var isMoving = false
    private var region: Region?
    private var display: Display?
    private var lastCheck: TimeInterval = 0

    init(mover: WindowMover) {
        self.mover = mover
    }

    func start() {
        guard monitors.isEmpty else { return }
        let events: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak self] event in
            self?.handle(event)
        }) {
            monitors.append(monitor)
        }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
        reset()
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            reset()
            guard Preferences.snapping, WindowAccess.isTrusted, let point = Self.pointer(),
                  let window = WindowAccess.window(at: point), !WindowAccess.isIgnored(window) else { return }
            self.window = window
            startFrame = window.frame
        case .leftMouseDragged:
            dragged()
        case .leftMouseUp:
            if isMoving, let window, let region, let display {
                mover.snap(window, to: region, on: display)
            }
            reset()
        default:
            break
        }
    }

    private func dragged() {
        guard let window, let startFrame, let point = Self.pointer() else { return }
        // Reading the window frame is a cross-process call; a few checks a second is plenty.
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastCheck > 0.03 else { return }
        lastCheck = now
        if !isMoving {
            // A move keeps the size; a resize from an edge doesn't.
            guard let frame = window.frame, frame.origin != startFrame.origin, frame.size == startFrame.size else { return }
            isMoving = true
        }
        let displays = DisplayCatalog.current()
        guard let screen = displays.first(where: { $0.frame.insetBy(dx: -1, dy: -1).contains(point) }),
              let region = SnapZones.region(at: point, in: screen.frame) else {
            self.region = nil
            preview.hide()
            return
        }
        self.region = region
        display = screen
        preview.show(Geometry.frame(for: .region(region), in: screen.visibleFrame, gap: Preferences.gap,
                                    current: startFrame))
    }

    private func reset() {
        window = nil
        startFrame = nil
        isMoving = false
        region = nil
        display = nil
        preview.hide()
    }

    /// The pointer in accessibility space.
    static func pointer() -> CGPoint? {
        guard let mainHeight = NSScreen.screens.first?.frame.height else { return nil }
        let location = NSEvent.mouseLocation
        return CGPoint(x: location.x, y: mainHeight - location.y)
    }
}
