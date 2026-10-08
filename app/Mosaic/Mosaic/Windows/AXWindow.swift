// Windows/AXWindow.swift
// Mosaic
//
// Another app's window, read and moved through the Accessibility API.

import AppKit
import ApplicationServices

struct AXWindow {
    let element: AXUIElement
    let pid: pid_t

    var app: NSRunningApplication? { NSRunningApplication(processIdentifier: pid) }

    /// Accessibility space.
    var frame: CGRect? {
        guard let position: CGPoint = value(kAXPositionAttribute, .cgPoint),
              let size: CGSize = value(kAXSizeAttribute, .cgSize) else { return nil }
        return CGRect(origin: position, size: size)
    }

    var title: String? { attribute(kAXTitleAttribute) as? String }
    var isMinimized: Bool { attribute(kAXMinimizedAttribute) as? Bool ?? false }
    var isStandard: Bool { attribute(kAXSubroleAttribute) as? String == kAXStandardWindowSubrole }

    /// Stable for the window's lifetime, for remembering frames to restore.
    var identity: Int { Int(CFHash(element)) }

    /// Moves and resizes. Size goes first and again last: apps clamp the size to the display the window is on.
    func setFrame(_ frame: CGRect) {
        let app = AXUIElementCreateApplication(pid)
        // Chromium-based apps animate every change while this is on, which makes the moves land late or not at all.
        let enhanced = AXWindow.attribute(of: app, "AXEnhancedUserInterface") as? Bool ?? false
        if enhanced { AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse) }
        defer {
            if enhanced { AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue) }
        }
        set(kAXSizeAttribute, frame.size)
        set(kAXPositionAttribute, frame.origin)
        set(kAXSizeAttribute, frame.size)
    }

    func raise() {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
    }

    // MARK: - Attributes

    private func attribute(_ name: String) -> AnyObject? {
        Self.attribute(of: element, name)
    }

    static func attribute(of element: AXUIElement, _ name: String) -> AnyObject? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func value<T>(_ name: String, _ type: AXValueType) -> T? {
        guard let raw = attribute(name), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(raw as! AXValue, type, pointer) else { return nil }
        return pointer.pointee
    }

    private func set(_ name: String, _ point: CGPoint) {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(element, name as CFString, value)
    }

    private func set(_ name: String, _ size: CGSize) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(element, name as CFString, value)
    }
}
