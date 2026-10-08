// Snapping/SnapZones.swift
// Mosaic
//
// Which region a window dragged to the edge of the screen snaps to.

import CoreGraphics

enum SnapZones {
    /// How close to the edge the pointer has to be.
    static let edge: CGFloat = 6
    /// How far from a corner still counts as the corner.
    static let corner: CGFloat = 80

    /// The region for a pointer position in accessibility space on a display, or nil away from the edges.
    /// Sides snap halves, corners quarters, the top maximizes and the bottom edge snaps thirds.
    static func region(at point: CGPoint, in screen: CGRect) -> Region? {
        let left = point.x <= screen.minX + edge
        let right = point.x >= screen.maxX - edge - 1
        let top = point.y <= screen.minY + edge
        let bottom = point.y >= screen.maxY - edge - 1
        let nearTop = point.y <= screen.minY + corner
        let nearBottom = point.y >= screen.maxY - corner
        let nearLeft = point.x <= screen.minX + corner
        let nearRight = point.x >= screen.maxX - corner

        if (left && nearTop) || (top && nearLeft) { return .topLeft }
        if (right && nearTop) || (top && nearRight) { return .topRight }
        if (left && nearBottom) || (bottom && nearLeft) { return .bottomLeft }
        if (right && nearBottom) || (bottom && nearRight) { return .bottomRight }
        if left { return .leftHalf }
        if right { return .rightHalf }
        if top { return .maximize }
        if bottom {
            let fraction = (point.x - screen.minX) / screen.width
            return fraction < 1.0 / 3.0 ? .firstThird : fraction < 2.0 / 3.0 ? .centerThird : .lastThird
        }
        return nil
    }
}
