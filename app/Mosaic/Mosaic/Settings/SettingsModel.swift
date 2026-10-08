// Settings/SettingsModel.swift
// Mosaic
//
// State shared by the Settings tabs.

import AppKit
import Observation

enum SettingsTab: Hashable {
    case general
    case arrangements
    case shortcuts
    case ignored
}

@Observable
final class SettingsModel {
    var tab: SettingsTab = .general
    var selection: UUID?
    private(set) var isTrusted = WindowAccess.isTrusted

    let store: ArrangementStore
    let engine: ArrangementEngine
    let launchAtLogin = LaunchAtLogin()
    @ObservationIgnored var onApply: ((Arrangement) -> Void)?

    init(store: ArrangementStore, engine: ArrangementEngine) {
        self.store = store
        self.engine = engine
    }

    func refreshTrust() {
        isTrusted = WindowAccess.isTrusted
    }

    func capture() {
        let arrangement = ArrangementEngine.capture(named: store.uniqueName("Layout"))
        store.add(arrangement)
        selection = arrangement.id
    }

    func newEmpty() {
        let displays = DisplayCatalog.current().map(\.ref)
        let arrangement = Arrangement(name: store.uniqueName("New Arrangement"), displays: displays, placements: [])
        store.add(arrangement)
        selection = arrangement.id
    }

    func delete(_ id: UUID) {
        store.remove(id)
        if selection == id { selection = store.arrangements.first?.id }
    }

    func apply(_ arrangement: Arrangement) {
        onApply?(arrangement)
    }

    /// Regular apps that are running now, for adding to an arrangement or the ignore list.
    static var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil
                && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}
