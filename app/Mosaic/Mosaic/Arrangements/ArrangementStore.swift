// Arrangements/ArrangementStore.swift
// Mosaic
//
// Saved arrangements, written to disk after every change.

import Foundation
import Observation

@Observable
final class ArrangementStore {
    private(set) var arrangements: [Arrangement] = []

    private let storage: Storage
    private let fileName = "arrangements.json"

    init(storage: Storage) {
        self.storage = storage
        arrangements = storage.load([Arrangement].self, from: fileName) ?? []
    }

    func arrangement(_ id: UUID) -> Arrangement? {
        arrangements.first { $0.id == id }
    }

    func add(_ arrangement: Arrangement) {
        arrangements.append(arrangement)
        save()
    }

    func update(_ arrangement: Arrangement) {
        guard let index = arrangements.firstIndex(where: { $0.id == arrangement.id }) else { return }
        arrangements[index] = arrangement
        save()
    }

    func remove(_ id: UUID) {
        arrangements.removeAll { $0.id == id }
        save()
    }

    /// The arrangement to apply for a set of displays: the first automatic one made for exactly that set.
    func automatic(for signature: String) -> Arrangement? {
        arrangements.first { $0.appliesAutomatically && $0.displaySignature == signature }
    }

    /// A name not yet taken, like "Layout 2".
    func uniqueName(_ base: String) -> String {
        let names = Set(arrangements.map(\.name))
        guard names.contains(base) else { return base }
        var number = 2
        while names.contains("\(base) \(number)") { number += 1 }
        return "\(base) \(number)"
    }

    private func save() {
        storage.save(arrangements, to: fileName)
    }
}
