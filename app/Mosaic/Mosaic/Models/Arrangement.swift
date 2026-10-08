// Models/Arrangement.swift
// Mosaic
//
// A saved layout: which app goes where, on which of a known set of displays.

import CoreGraphics
import Foundation

/// Recognizes a monitor across reconnects. Two identical monitors are told apart by their left-to-right order.
struct DisplayIdentity: Codable, Hashable {
    var vendor: UInt32
    var model: UInt32
    var serial: UInt32
    var isBuiltin: Bool
    var name: String

    var key: String { isBuiltin ? "builtin" : "\(vendor)-\(model)-\(serial)" }
}

/// One display of an arrangement, with where it sat so the editor can draw the setup.
struct DisplayRef: Codable, Hashable {
    var identity: DisplayIdentity
    /// Position among displays with the same identity, left to right.
    var ordinal: Int
    var frame: CGRect

    var key: String { "\(identity.key)#\(ordinal)" }
}

struct Placement: Codable, Hashable, Identifiable {
    var id = UUID()
    var bundleID: String
    var appName: String
    /// Index into the arrangement's displays.
    var display: Int
    var area: Area
}

struct Arrangement: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var displays: [DisplayRef]
    var placements: [Placement]
    /// Applies itself when exactly these displays are connected.
    var appliesAutomatically = true

    /// Identifies the set of displays, regardless of order.
    var displaySignature: String {
        Self.signature(of: displays)
    }

    static func signature(of displays: [DisplayRef]) -> String {
        displays.map(\.key).sorted().joined(separator: "|")
    }
}
