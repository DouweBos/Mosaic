// Windows/WindowMover.swift
// Mosaic
//
// Snaps windows to regions, moves them between displays and puts them back.

import AppKit

final class WindowMover {
    /// Frames from before Mosaic first moved each window, for Restore.
    private var originalFrames: [Int: CGRect] = [:]

    func snapFocusedWindow(to region: Region) {
        guard let window = WindowAccess.focusedWindow() else { return NSSound.beep() }
        snap(window, to: region)
    }

    func snap(_ window: AXWindow, to region: Region, on display: Display? = nil) {
        guard !WindowAccess.isIgnored(window), let frame = window.frame,
              let display = display ?? Self.display(containing: frame) else { return }
        move(window, to: Geometry.frame(for: .region(region), in: display.visibleFrame, gap: Preferences.gap, current: frame))
    }

    /// Puts a window in an area of a specific display, as arrangements do.
    func place(_ window: AXWindow, in area: Area, on display: Display) {
        let target = Geometry.frame(for: area, in: display.visibleFrame, gap: Preferences.gap, current: window.frame)
        move(window, to: target)
    }

    /// Moves the focused window to the next or previous display, keeping its relative spot.
    func moveFocusedWindow(displayOffset offset: Int) {
        guard let window = WindowAccess.focusedWindow(), !WindowAccess.isIgnored(window), let frame = window.frame
        else { return NSSound.beep() }
        let displays = DisplayCatalog.current()
        guard displays.count > 1, let index = Geometry.bestMatch(for: frame, among: displays.map(\.visibleFrame))
        else { return NSSound.beep() }
        let source = displays[index].visibleFrame
        let target = displays[(index + offset + displays.count) % displays.count].visibleFrame
        let unit = Geometry.unitRect(of: frame, in: source)
        let width = min(unit.width * target.width, target.width), height = min(unit.height * target.height, target.height)
        move(window, to: CGRect(x: target.minX + unit.x * target.width, y: target.minY + unit.y * target.height,
                                width: width, height: height).integral)
    }

    func restoreFocusedWindow() {
        guard let window = WindowAccess.focusedWindow(), let frame = originalFrames.removeValue(forKey: window.identity)
        else { return NSSound.beep() }
        window.setFrame(frame)
    }

    private func move(_ window: AXWindow, to target: CGRect) {
        if originalFrames[window.identity] == nil, let frame = window.frame {
            originalFrames[window.identity] = frame
        }
        window.setFrame(target)
    }

    static func display(containing frame: CGRect) -> Display? {
        let displays = DisplayCatalog.current()
        return Geometry.bestMatch(for: frame, among: displays.map(\.visibleFrame)).map { displays[$0] }
    }
}
