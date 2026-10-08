// Settings/SettingsView.swift
// Mosaic
//
// The Settings window's tabs. The window has a fixed size per tab: grouped forms scroll, so they report no height.

import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        TabView(selection: $model.tab) {
            Tab("General", systemImage: "gearshape", value: .general) {
                GeneralSettings(model: model)
            }
            Tab("Arrangements", systemImage: "square.grid.2x2", value: .arrangements) {
                ArrangementsSettings(model: model)
            }
            Tab("Shortcuts", systemImage: "keyboard", value: .shortcuts) {
                ShortcutSettings()
            }
            Tab("Ignored Apps", systemImage: "eye.slash", value: .ignored) {
                IgnoredAppsSettings()
            }
        }
        .scenePadding()
        // Sized per tab so each fills the window; the hosting controller resizes the window to match.
        .frame(width: size.width, height: size.height)
    }

    private var size: CGSize {
        switch model.tab {
        case .general: CGSize(width: 560, height: 480)
        case .arrangements: CGSize(width: 900, height: 680)
        case .shortcuts: CGSize(width: 560, height: 680)
        case .ignored: CGSize(width: 560, height: 480)
        }
    }
}

private struct GeneralSettings: View {
    let model: SettingsModel

    @AppStorage(SettingKey.snapping) private var snapping = true
    @AppStorage(SettingKey.gap) private var gap = 0.0
    @AppStorage(SettingKey.followNewDisplays) private var followDisplays = true

    var body: some View {
        Form {
            Section {
                if model.isTrusted {
                    Label("Mosaic can move windows.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Mosaic needs Accessibility access to move windows.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.warning)
                        Text("Turn Mosaic on in Privacy & Security → Accessibility. It picks up the change by itself.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        HStack {
                            Button("Grant Access…") { WindowAccess.requestTrust() }
                            Button("Open System Settings") { WindowAccess.openAccessibilitySettings() }
                        }
                    }
                }
            }
            Section {
                Toggle("Snap windows dragged to a screen edge", isOn: $snapping)
                LabeledContent("Gap between windows") {
                    HStack {
                        Slider(value: $gap, in: 0...32, step: 2).frame(width: 160)
                        Text("\(Int(gap)) pt").monospacedDigit().frame(width: 40, alignment: .trailing)
                    }
                }
            }
            Section {
                Toggle("Apply arrangements when their displays connect", isOn: $followDisplays)
                Toggle("Open at login", isOn: Binding(get: { model.launchAtLogin.isEnabled }, set: model.launchAtLogin.set))
                if let error = model.launchAtLogin.error {
                    Text(error).font(.caption).foregroundStyle(Theme.danger)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutSettings: View {
    var body: some View {
        Form {
            ForEach(Array(Region.groups.enumerated()), id: \.offset) { _, group in
                Section {
                    ForEach(group) { region in
                        if let name = KeyboardShortcuts.Name.regions[region] {
                            KeyboardShortcuts.Recorder(region.title, name: name)
                        }
                    }
                }
            }
            Section {
                KeyboardShortcuts.Recorder("Next Display", name: .nextDisplay)
                KeyboardShortcuts.Recorder("Previous Display", name: .previousDisplay)
                KeyboardShortcuts.Recorder("Restore", name: .restore)
            }
        }
        .formStyle(.grouped)
    }
}

private struct IgnoredAppsSettings: View {
    @State private var ignored = Array(Preferences.ignoredApps).sorted()

    var body: some View {
        Form {
            Section {
                if ignored.isEmpty {
                    Text("Mosaic snaps and arranges every app.")
                        .foregroundStyle(Theme.textSecondary)
                }
                ForEach(ignored, id: \.self) { bundleID in
                    HStack {
                        AppIcon(bundleID: bundleID)
                        Text(Self.name(of: bundleID))
                        Spacer()
                        Button("Remove", systemImage: "minus.circle") { set(bundleID, false) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("Mosaic leaves these apps' windows alone.")
            } footer: {
                Menu("Add App") {
                    ForEach(SettingsModel.runningApps.filter { !ignored.contains($0.bundleIdentifier ?? "") },
                            id: \.processIdentifier) { app in
                        Button(app.localizedName ?? "") { set(app.bundleIdentifier ?? "", true) }
                    }
                }
                .fixedSize()
            }
        }
        .formStyle(.grouped)
    }

    private func set(_ bundleID: String, _ isIgnored: Bool) {
        Preferences.setIgnored(bundleID, isIgnored)
        ignored = Array(Preferences.ignoredApps).sorted()
    }

    static func name(of bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}
