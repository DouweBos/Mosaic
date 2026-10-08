// Windows/RegionStep.swift
// Mosaic
//
// Repeating a shortcut on a window that's already there carries it on to the neighboring display:
// right half, then the next display's left half, and so on, half a display at a time.

import CoreGraphics

enum Direction {
    case left, right, up, down
}

enum RegionStep {
    private static let continuations: [Region: (Direction, Region)] = [
        .rightHalf: (.right, .leftHalf), .leftHalf: (.left, .rightHalf),
        .topRight: (.right, .topLeft), .bottomRight: (.right, .bottomLeft),
        .topLeft: (.left, .topRight), .bottomLeft: (.left, .bottomRight),
        .lastThird: (.right, .firstThird), .firstThird: (.left, .lastThird),
        .lastTwoThirds: (.right, .firstTwoThirds), .firstTwoThirds: (.left, .lastTwoThirds),
        .topHalf: (.up, .bottomHalf), .bottomHalf: (.down, .topHalf)
    ]

    /// Where a window already in `region` goes next: the direction to travel and its spot on that display.
    /// Centered regions have nowhere to go.
    static func continuation(of region: Region) -> (Direction, Region)? {
        continuations[region]
    }

    /// The nearest display beside `display` in a direction, preferring ones that overlap it across that direction.
    static func neighbor(of display: CGRect, toward direction: Direction, among displays: [CGRect]) -> Int? {
        let candidates = displays.indices.filter { index in
            let other = displays[index]
            guard other != display else { return false }
            return switch direction {
            case .right: other.midX > display.maxX - 1 || other.minX >= display.maxX - 1
            case .left: other.midX < display.minX + 1 || other.maxX <= display.minX + 1
            case .down: other.minY >= display.maxY - 1
            case .up: other.maxY <= display.minY + 1
            }
        }
        return candidates.min { score(displays[$0], from: display, direction) < score(displays[$1], from: display, direction) }
    }

    /// Distance along the direction, with displays that don't line up across it pushed back.
    private static func score(_ other: CGRect, from display: CGRect, _ direction: Direction) -> CGFloat {
        let horizontal = direction == .left || direction == .right
        let distance = horizontal ? abs(other.midX - display.midX) : abs(other.midY - display.midY)
        let overlaps = horizontal
            ? other.minY < display.maxY && other.maxY > display.minY
            : other.minX < display.maxX && other.maxX > display.minX
        return overlaps ? distance : distance + 100_000
    }

    /// Whether a window frame already sits in a region's spot.
    static func isAt(_ frame: CGRect, _ target: CGRect, tolerance: CGFloat = 10) -> Bool {
        abs(frame.minX - target.minX) <= tolerance && abs(frame.minY - target.minY) <= tolerance
            && abs(frame.width - target.width) <= tolerance && abs(frame.height - target.height) <= tolerance
    }
}
