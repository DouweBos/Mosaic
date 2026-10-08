// Displays/DisplayMonitor.swift
// Mosaic
//
// Reports when the set of connected displays changes, once things have settled.

import AppKit

final class DisplayMonitor {
    var onChange: ((String) -> Void)?

    private var observer: NSObjectProtocol?
    private var pending: Task<Void, Never>?
    private var lastSignature = DisplayCatalog.signature

    func start() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        }
    }

    private func screensChanged() {
        // Docks connect displays one at a time and windows shuffle meanwhile; wait for quiet.
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !Task.isCancelled else { return }
            let signature = DisplayCatalog.signature
            guard signature != self.lastSignature else { return }
            self.lastSignature = signature
            self.onChange?(signature)
        }
    }
}
