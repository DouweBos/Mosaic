// Windows/WindowAccess.swift
// Mosaic
//
// Finding other apps' windows. All of it needs Accessibility permission.

import AppKit
import ApplicationServices

enum WindowAccess {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that leads to Privacy & Security → Accessibility.
    static func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// The window you're working in.
    static func focusedWindow() -> AXWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let element = AXUIElementCreateApplication(app.processIdentifier)
        guard let window = AXWindow.attribute(of: element, kAXFocusedWindowAttribute) else { return nil }
        // swiftlint:disable:next force_cast
        return AXWindow(element: window as! AXUIElement, pid: app.processIdentifier)
    }

    /// An app's ordinary windows, frontmost first, leaving out minimized ones, panels and sheets.
    static func windows(of pid: pid_t) -> [AXWindow] {
        let app = AXUIElementCreateApplication(pid)
        guard let list = AXWindow.attribute(of: app, kAXWindowsAttribute) as? [AXUIElement] else { return [] }
        return list.map { AXWindow(element: $0, pid: pid) }.filter { $0.isStandard && !$0.isMinimized }
    }

    /// The window under a point in accessibility space.
    static func window(at point: CGPoint) -> AXWindow? {
        let systemWide = AXUIElementCreateSystemWide()
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &hit) == .success,
              var element = hit else { return nil }
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        guard pid != ProcessInfo.processInfo.processIdentifier else { return nil }
        // Walk up from the control under the pointer to its window.
        for _ in 0..<20 {
            if AXWindow.attribute(of: element, kAXRoleAttribute) as? String == kAXWindowRole {
                return AXWindow(element: element, pid: pid)
            }
            if let window = AXWindow.attribute(of: element, kAXWindowAttribute) {
                // swiftlint:disable:next force_cast
                return AXWindow(element: window as! AXUIElement, pid: pid)
            }
            guard let parent = AXWindow.attribute(of: element, kAXParentAttribute) else { return nil }
            // swiftlint:disable:next force_cast
            element = parent as! AXUIElement
        }
        return nil
    }

    static func isIgnored(_ window: AXWindow) -> Bool {
        guard let bundleID = window.app?.bundleIdentifier else { return false }
        return Preferences.ignoredApps.contains(bundleID)
    }
}
