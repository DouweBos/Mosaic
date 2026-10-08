// App/AppDelegate.swift
// Mosaic
//
// Wires the window mover, snapping, shortcuts and arrangements together, and waits for Accessibility access.

import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    let mover = WindowMover()
    let store = ArrangementStore(storage: .live)
    lazy var engine = ArrangementEngine(mover: mover)
    lazy var settingsModel = SettingsModel(store: store, engine: engine)

    private lazy var snapMonitor = SnapMonitor(mover: mover)
    private let displayMonitor = DisplayMonitor()
    private lazy var settingsWindow = SettingsWindowController(model: settingsModel)
    private var statusItem: StatusItemController?
    private var trustTimer: Timer?

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    override init() {
        Preferences.registerDefaults()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isRunningTests else { return }

        statusItem = StatusItemController(delegate: self)
        settingsModel.onApply = { [weak self] arrangement in self?.engine.apply(arrangement) }

        KeyboardShortcuts.onKeyDown(for: .nextDisplay) { [weak self] in self?.mover.moveFocusedWindow(displayOffset: 1) }
        KeyboardShortcuts.onKeyDown(for: .previousDisplay) { [weak self] in self?.mover.moveFocusedWindow(displayOffset: -1) }
        KeyboardShortcuts.onKeyDown(for: .restore) { [weak self] in self?.mover.restoreFocusedWindow() }
        for (region, name) in KeyboardShortcuts.Name.regions {
            KeyboardShortcuts.onKeyDown(for: name) { [weak self] in self?.mover.snapFocusedWindow(to: region) }
        }

        engine.start()
        displayMonitor.onChange = { [weak self] signature in self?.displaysChanged(signature) }
        displayMonitor.start()
        snapMonitor.start()

        if !WindowAccess.isTrusted {
            settingsWindow.show(tab: .general)
            waitForTrust()
        }
        #if DEBUG
        if let bundleID = UserDefaults.standard.string(forKey: "MosaicSelfTest") {
            Task { await SelfTest(mover: mover, engine: engine).run(bundleID: bundleID) }
        }
        #endif
        if let tab = UserDefaults.standard.string(forKey: "MosaicOpenSettings") {
            settingsWindow.show(tab: SettingsTab(rawValue: tab) ?? .arrangements)
        }
    }

    func showSettings(tab: SettingsTab? = nil) {
        settingsWindow.show(tab: tab)
    }

    /// Saves the current layout and opens it for editing.
    func captureArrangement() {
        guard WindowAccess.isTrusted else { return showSettings(tab: .general) }
        let arrangement = ArrangementEngine.capture(named: store.uniqueName("Layout"))
        store.add(arrangement)
        settingsModel.selection = arrangement.id
        showSettings(tab: .arrangements)
    }

    private func displaysChanged(_ signature: String) {
        guard Preferences.followNewDisplays, let arrangement = store.automatic(for: signature) else { return }
        engine.apply(arrangement)
    }

    /// Accessibility access is granted in System Settings while Mosaic runs; notice it without a relaunch.
    private func waitForTrust() {
        trustTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard WindowAccess.isTrusted else { return }
                timer.invalidate()
                self?.settingsModel.refreshTrust()
            }
        }
    }
}
