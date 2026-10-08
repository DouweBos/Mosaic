// Windows/WindowMover.swift
// Mosaic
//
// Snaps windows to regions, moves them between displays and puts them back.

import AppKit

final class WindowMover {
    /// Frames from before Mosaic first moved each window, for Restore.
    private var originalFrames: [Int: CGRect] = [:]

    /// Snaps the focused window; if it's already in that spot, carries it on to the next display over.
    func snapFocusedWindow(to region: Region) {
        guard let window = WindowAccess.focusedWindow() else { return NSSound.beep() }
        step(window, to: region)
    }

    func step(_ window: AXWindow, to region: Region) {
        guard !WindowAccess.isIgnored(window), let frame = window.frame else { return }
        let displays = DisplayCatalog.current()
        guard let index = Geometry.bestMatch(for: frame, among: displays.map(\.visibleFrame)) else { return }
        let display = displays[index]
        let target = Geometry.frame(for: .region(region), in: display.visibleFrame, gap: Preferences.gap, current: frame)
        if RegionStep.isAt(frame, target), let (direction, next) = RegionStep.continuation(of: region),
           let neighbor = RegionStep.neighbor(of: display.frame, toward: direction, among: displays.map(\.frame)) {
            snap(window, to: next, on: displays[neighbor])
        } else {
            snap(window, to: region, on: display)
        }
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
        guard let window = WindowAccess.focusedWindow() else { return NSSound.beep() }
        move(window, displayOffset: offset)
    }

    func move(_ window: AXWindow, displayOffset offset: Int) {
        guard !WindowAccess.isIgnored(window), let frame = window.frame else { return NSSound.beep() }
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
        guard let window = WindowAccess.focusedWindow() else { return NSSound.beep() }
        restore(window)
    }

    func restore(_ window: AXWindow) {
        guard let frame = originalFrames.removeValue(forKey: window.identity) else { return NSSound.beep() }
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
