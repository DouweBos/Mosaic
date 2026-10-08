// Windows/Geometry.swift
// Mosaic
//
// Frame math. Everything here is in the accessibility coordinate space: origin at the top-left of the main
// display, y growing downward, which is what window positions use.

import CoreGraphics

enum Geometry {
    /// Converts a Cocoa screen rect (origin bottom-left of the main display) to accessibility space.
    static func flip(_ rect: CGRect, mainHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: mainHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    /// The window frame for an area of a display's usable rect, with `gap` points around and between windows.
    static func frame(for area: Area, in visible: CGRect, gap: CGFloat = 0, current: CGRect? = nil) -> CGRect {
        guard let unit = area.unitRect else {
            // Center: same size, clamped to the display.
            let size = current?.size ?? CGSize(width: visible.width * 0.6, height: visible.height * 0.6)
            let width = min(size.width, visible.width), height = min(size.height, visible.height)
            return CGRect(x: (visible.midX - width / 2).rounded(), y: (visible.midY - height / 2).rounded(),
                          width: width, height: height)
        }
        var rect = CGRect(x: visible.minX + unit.x * visible.width, y: visible.minY + unit.y * visible.height,
                          width: unit.width * visible.width, height: unit.height * visible.height)
        guard gap > 0 else { return rect.integral }
        // Full gap at the display edges, half a gap on sides shared with a neighbor, so gaps look even.
        let left = unit.x <= 0.001 ? gap : gap / 2
        let top = unit.y <= 0.001 ? gap : gap / 2
        let right = unit.x + unit.width >= 0.999 ? gap : gap / 2
        let bottom = unit.y + unit.height >= 0.999 ? gap : gap / 2
        rect.origin.x += left
        rect.origin.y += top
        rect.size.width -= left + right
        rect.size.height -= top + bottom
        return rect.integral
    }

    /// The window frame as fractions of the display it's on.
    static func unitRect(of frame: CGRect, in visible: CGRect) -> UnitRect {
        UnitRect(x: (frame.minX - visible.minX) / visible.width, y: (frame.minY - visible.minY) / visible.height,
                 width: frame.width / visible.width, height: frame.height / visible.height)
    }

    /// The preset the frame matches within `tolerance` points, or the exact spot when none does.
    static func area(matching frame: CGRect, in visible: CGRect, tolerance: CGFloat = 24) -> Area {
        for region in Region.allCases {
            guard region.unitRect != nil else { continue }
            let target = self.frame(for: .region(region), in: visible)
            let close = abs(target.minX - frame.minX) <= tolerance && abs(target.minY - frame.minY) <= tolerance
                && abs(target.width - frame.width) <= tolerance && abs(target.height - frame.height) <= tolerance
            if close { return .region(region) }
        }
        return .custom(unitRect(of: frame, in: visible))
    }

    /// The rect from `rects` that holds most of `frame`, falling back to the one nearest its center.
    static func bestMatch(for frame: CGRect, among rects: [CGRect]) -> Int? {
        guard !rects.isEmpty else { return nil }
        let overlaps = rects.map { rect -> CGFloat in
            let overlap = rect.intersection(frame)
            return overlap.isNull ? 0 : overlap.width * overlap.height
        }
        if let best = overlaps.indices.max(by: { overlaps[$0] < overlaps[$1] }), overlaps[best] > 0 { return best }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return rects.indices.min { distance(center, rects[$0]) < distance(center, rects[$1]) }
    }

    private static func distance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        hypot(point.x - rect.midX, point.y - rect.midY)
    }
}
