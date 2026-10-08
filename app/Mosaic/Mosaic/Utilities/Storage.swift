// Utilities/Storage.swift
// Mosaic
//
// JSON files in Application Support.

import Foundation

struct Storage {
    let root: URL

    static let live = Storage(root: defaultRoot)

    private static var defaultRoot: URL {
        if let override = UserDefaults.standard.string(forKey: "MosaicStorage") {
            return URL(fileURLWithPath: (override as NSString).expandingTildeInPath, isDirectory: true)
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Mosaic", isDirectory: true)
    }

    func load<Value: Decodable>(_ type: Value.Type, from name: String) -> Value? {
        guard let data = try? Data(contentsOf: root.appendingPathComponent(name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func save(_ value: some Encodable, to name: String) {
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(value).write(to: root.appendingPathComponent(name), options: .atomic)
        } catch {
            NSLog("Mosaic: couldn't save \(name): \(error)")
        }
    }
}
