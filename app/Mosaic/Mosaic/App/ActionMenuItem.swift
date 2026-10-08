// App/ActionMenuItem.swift
// Mosaic
//
// A menu item that runs a closure.

import AppKit

final class ActionMenuItem: NSMenuItem, NSMenuItemValidation {
    private let handler: () -> Void
    /// Menus enable items through validation, so this stands in for `isEnabled`.
    var isAvailable = true

    init(_ title: String, symbol: String? = nil, state: NSControl.StateValue = .off, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
        self.state = state
        if let symbol { image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func run() { handler() }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool { isAvailable }
}
