// App/main.swift
// Mosaic
//
// Application entry point. Plain AppKit: the menu bar item and Settings window are managed by hand.

import AppKit

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
}
