// Settings/ArrangementsSettings.swift
// Mosaic
//
// The arrangement list and, for the selected one, its editor.

import SwiftUI

struct ArrangementsSettings: View {
    @Bindable var model: SettingsModel

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 200)
            Divider()
            if let id = model.selection, model.store.arrangement(id) != nil {
                ArrangementEditor(model: model, arrangement: binding(for: id))
                    .id(id)
            } else {
                ContentUnavailableView {
                    Label("No Arrangement Selected", systemImage: "square.grid.2x2")
                } description: {
                    Text("Lay out your windows and save the layout, or start from scratch.")
                } actions: {
                    Button("Save Current Layout") { model.capture() }
                        .disabled(!model.isTrusted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if model.selection == nil { model.selection = model.store.arrangements.first?.id }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $model.selection) {
                ForEach(model.store.arrangements) { arrangement in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(arrangement.name)
                        Text(summary(arrangement))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .tag(arrangement.id)
                    .contextMenu {
                        Button("Delete", role: .destructive) { model.delete(arrangement.id) }
                    }
                }
            }
            .listStyle(.sidebar)
            Divider()
            HStack(spacing: Theme.Spacing.xs) {
                Menu {
                    Button("Save Current Layout") { model.capture() }
                        .disabled(!model.isTrusted)
                    Button("New Empty Arrangement") { model.newEmpty() }
                } label: {
                    Image(systemName: "plus")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("Add Arrangement")
                Button {
                    if let id = model.selection { model.delete(id) }
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(model.selection == nil)
                .accessibilityLabel("Delete Arrangement")
                Spacer()
            }
            .padding(Theme.Spacing.sm)
        }
    }

    private func summary(_ arrangement: Arrangement) -> String {
        let apps = arrangement.placements.count == 1 ? "1 app" : "\(arrangement.placements.count) apps"
        let displays = arrangement.displays.count == 1 ? "1 display" : "\(arrangement.displays.count) displays"
        return "\(apps) · \(displays)"
    }

    private func binding(for id: UUID) -> Binding<Arrangement> {
        Binding {
            model.store.arrangement(id) ?? Arrangement(name: "", displays: [], placements: [])
        } set: { model.store.update($0) }
    }
}
