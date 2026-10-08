// Models/Region.swift
// Mosaic
//
// The preset spots a window can snap to, as fractions of a display's usable area.

import CoreGraphics

/// A rectangle in fractions of a display, measured from its top-left corner.
struct UnitRect: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    static let full = UnitRect(x: 0, y: 0, width: 1, height: 1)
}

enum Region: String, Codable, CaseIterable, Identifiable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case firstThird, centerThird, lastThird, firstTwoThirds, lastTwoThirds
    case maximize, almostMaximize, center

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .firstThird: "First Third"
        case .centerThird: "Center Third"
        case .lastThird: "Last Third"
        case .firstTwoThirds: "First Two Thirds"
        case .lastTwoThirds: "Last Two Thirds"
        case .maximize: "Maximize"
        case .almostMaximize: "Almost Maximize"
        case .center: "Center"
        }
    }

    var symbol: String {
        switch self {
        case .leftHalf: "rectangle.lefthalf.filled"
        case .rightHalf: "rectangle.righthalf.filled"
        case .topHalf: "rectangle.tophalf.filled"
        case .bottomHalf: "rectangle.bottomhalf.filled"
        case .topLeft: "rectangle.inset.topleft.filled"
        case .topRight: "rectangle.inset.topright.filled"
        case .bottomLeft: "rectangle.inset.bottomleft.filled"
        case .bottomRight: "rectangle.inset.bottomright.filled"
        case .firstThird: "rectangle.leadingthird.inset.filled"
        case .centerThird: "rectangle.center.inset.filled"
        case .lastThird: "rectangle.trailingthird.inset.filled"
        case .firstTwoThirds: "rectangle.split.3x1"
        case .lastTwoThirds: "rectangle.split.3x1"
        case .maximize: "rectangle.fill"
        case .almostMaximize: "rectangle.inset.filled"
        case .center: "rectangle.center.inset.filled"
        }
    }

    /// Groups for menus and pickers, in display order.
    static let groups: [[Region]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds],
        [.maximize, .almostMaximize, .center]
    ]

    /// The area this region covers. Center keeps the window's size, so it has none of its own.
    var unitRect: UnitRect? {
        let third: CGFloat = 1.0 / 3.0
        return switch self {
        case .leftHalf: UnitRect(x: 0, y: 0, width: 0.5, height: 1)
        case .rightHalf: UnitRect(x: 0.5, y: 0, width: 0.5, height: 1)
        case .topHalf: UnitRect(x: 0, y: 0, width: 1, height: 0.5)
        case .bottomHalf: UnitRect(x: 0, y: 0.5, width: 1, height: 0.5)
        case .topLeft: UnitRect(x: 0, y: 0, width: 0.5, height: 0.5)
        case .topRight: UnitRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
        case .bottomLeft: UnitRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
        case .bottomRight: UnitRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        case .firstThird: UnitRect(x: 0, y: 0, width: third, height: 1)
        case .centerThird: UnitRect(x: third, y: 0, width: third, height: 1)
        case .lastThird: UnitRect(x: 2 * third, y: 0, width: third, height: 1)
        case .firstTwoThirds: UnitRect(x: 0, y: 0, width: 2 * third, height: 1)
        case .lastTwoThirds: UnitRect(x: third, y: 0, width: 2 * third, height: 1)
        case .maximize: .full
        case .almostMaximize: UnitRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)
        case .center: nil
        }
    }
}

/// Where a window goes on its display: a preset, or an exact spot captured from a layout.
enum Area: Codable, Hashable {
    case region(Region)
    case custom(UnitRect)

    var title: String {
        switch self {
        case .region(let region): region.title
        case .custom: "Custom"
        }
    }

    var unitRect: UnitRect? {
        switch self {
        case .region(let region): region.unitRect
        case .custom(let rect): rect
        }
    }
}
