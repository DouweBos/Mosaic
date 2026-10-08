// Displays/DisplayCatalog.swift
// Mosaic
//
// The connected displays, identified so arrangements can find them again after a reconnect.

import AppKit

struct Display: Identifiable {
    let id: CGDirectDisplayID
    let ref: DisplayRef
    /// Accessibility space.
    let frame: CGRect
    /// Accessibility space, without the menu bar and Dock.
    let visibleFrame: CGRect

    var name: String { ref.identity.name }
}

enum DisplayCatalog {
    /// Connected displays, left to right.
    static func current() -> [Display] {
        let screens = NSScreen.screens
        guard let mainHeight = screens.first?.frame.height else { return [] }
        var counts: [String: Int] = [:]
        return screens
            .sorted { $0.frame.minX == $1.frame.minX ? $0.frame.minY < $1.frame.minY : $0.frame.minX < $1.frame.minX }
            .compactMap { screen in
                guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
                else { return nil }
                let id = CGDirectDisplayID(number.uint32Value)
                let identity = DisplayIdentity(vendor: CGDisplayVendorNumber(id), model: CGDisplayModelNumber(id),
                                               serial: CGDisplaySerialNumber(id), isBuiltin: CGDisplayIsBuiltin(id) != 0,
                                               name: screen.localizedName)
                let ordinal = counts[identity.key, default: 0]
                counts[identity.key] = ordinal + 1
                let frame = Geometry.flip(screen.frame, mainHeight: mainHeight)
                return Display(id: id, ref: DisplayRef(identity: identity, ordinal: ordinal, frame: frame), frame: frame,
                               visibleFrame: Geometry.flip(screen.visibleFrame, mainHeight: mainHeight))
            }
    }

    static var signature: String {
        Arrangement.signature(of: current().map(\.ref))
    }

    /// The connected display for each of an arrangement's displays: same monitor where possible, else same position.
    static func resolve(_ refs: [DisplayRef], in displays: [Display]) -> [Display?] {
        var unused = displays
        var result: [Display?] = refs.map { ref in
            guard let index = unused.firstIndex(where: { $0.ref.key == ref.key }) else { return nil }
            return unused.remove(at: index)
        }
        for index in result.indices where result[index] == nil && !unused.isEmpty {
            result[index] = unused.removeFirst()
        }
        return result
    }
}
