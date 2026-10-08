// App/SettingsWindowController.swift
// Mosaic
//
// The Settings window, hosted by hand since Mosaic has no SwiftUI scenes.

import AppKit
import SwiftUI

final class SettingsWindowController {
    private let model: SettingsModel
    private var window: NSWindow?

    init(model: SettingsModel) {
        self.model = model
    }

    func show(tab: SettingsTab? = nil) {
        if let tab { model.tab = tab }
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
        window.title = "Mosaic Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
