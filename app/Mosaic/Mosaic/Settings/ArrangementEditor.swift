// Settings/ArrangementEditor.swift
// Mosaic
//
// Edits one arrangement: its name, when it applies, and where each app goes, on a picture of its displays.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ArrangementEditor: View {
    let model: SettingsModel
    @Binding var arrangement: Arrangement
    @State private var selectedPlacement: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header
            DisplayCanvas(arrangement: $arrangement, selection: $selectedPlacement)
                .frame(height: 230)
            placements
        }
        .padding(Theme.Spacing.lg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                TextField("Name", text: $arrangement.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                Button("Apply Now") { model.apply(arrangement) }
                    .disabled(!model.isTrusted)
                    .keyboardShortcut(.defaultAction)
            }
            Toggle("Apply automatically when these displays connect", isOn: $arrangement.appliesAutomatically)
            HStack {
                Text(arrangement.displays.enumerated().map { "\($0 + 1). \($1.identity.name)" }.joined(separator: "   "))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Spacer()
                if arrangement.displaySignature != DisplayCatalog.signature {
                    Button("Use Current Displays") { adoptCurrentDisplays() }
                        .controlSize(.small)
                        .help("Make this arrangement for the displays connected now")
                }
            }
        }
    }

    private var placements: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            List(selection: $selectedPlacement) {
                ForEach($arrangement.placements) { $placement in
                    PlacementRow(placement: $placement, displays: arrangement.displays) {
                        arrangement.placements.removeAll { $0.id == placement.id }
                    }
                    .tag(placement.id)
                }
            }
            .listStyle(.bordered)
            .alternatingRowBackgrounds()
            .overlay {
                if arrangement.placements.isEmpty {
                    Text("Add the apps this arrangement should place.")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            HStack {
                Menu("Add App") {
                    let added = Set(arrangement.placements.map(\.bundleID))
                    ForEach(SettingsModel.runningApps.filter { !added.contains($0.bundleIdentifier ?? "") },
                            id: \.processIdentifier) { app in
                        Button(app.localizedName ?? "") {
                            add(bundleID: app.bundleIdentifier ?? "", name: app.localizedName ?? "")
                        }
                    }
                    Divider()
                    Button("Choose Application…") { chooseApplication() }
                }
                .fixedSize()
                Spacer()
                Text("Drag an app on the displays above to move it.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func add(bundleID: String, name: String) {
        let placement = Placement(bundleID: bundleID, appName: name, display: 0, area: .region(.maximize))
        arrangement.placements.append(placement)
        selectedPlacement = placement.id
    }

    private func chooseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return }
        add(bundleID: bundleID, name: FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: ""))
    }

    /// Re-targets the arrangement at the connected displays, keeping each app on the display at the same position.
    private func adoptCurrentDisplays() {
        let current = DisplayCatalog.current().map(\.ref)
        guard !current.isEmpty else { return }
        for index in arrangement.placements.indices {
            arrangement.placements[index].display = min(arrangement.placements[index].display, current.count - 1)
        }
        arrangement.displays = current
    }
}

private struct PlacementRow: View {
    @Binding var placement: Placement
    let displays: [DisplayRef]
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            AppIcon(bundleID: placement.bundleID)
            Text(placement.appName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("Display", selection: $placement.display) {
                ForEach(displays.indices, id: \.self) { index in
                    Text("\(index + 1). \(displays[index].identity.name)").tag(index)
                }
            }
            .labelsHidden()
            .frame(width: 180)
            Picker("Position", selection: $placement.area) {
                ForEach(Array(Region.groups.enumerated()), id: \.offset) { _, group in
                    ForEach(group) { region in
                        Label(region.title, systemImage: region.symbol).tag(Area.region(region))
                    }
                    Divider()
                }
                if case .custom = placement.area {
                    Text("Custom").tag(placement.area)
                }
            }
            .labelsHidden()
            .frame(width: 170)
            Button("Remove", systemImage: "minus.circle", action: onRemove)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
    }
}
