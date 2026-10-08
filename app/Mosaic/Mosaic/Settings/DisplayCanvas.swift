// Settings/DisplayCanvas.swift
// Mosaic
//
// A scaled picture of an arrangement's displays with each app drawn where it goes. Apps can be dragged
// to another spot: where they're dropped on a display picks the region.

import SwiftUI

struct DisplayCanvas: View {
    @Binding var arrangement: Arrangement
    @Binding var selection: UUID?
    @State private var dragging: UUID?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let layout = CanvasLayout(displays: arrangement.displays, size: proxy.size)
            ZStack(alignment: .topLeading) {
                ForEach(arrangement.displays.indices, id: \.self) { index in
                    displayView(index, frame: layout.rect(forDisplay: index))
                }
                ForEach(arrangement.placements) { placement in
                    if let rect = layout.rect(for: placement) {
                        tile(placement, rect: rect)
                            .offset(dragging == placement.id ? dragOffset : .zero)
                            .gesture(drag(placement, rect: rect, layout: layout))
                            .onTapGesture { selection = placement.id }
                    }
                }
            }
        }
        .background(Theme.subtleFill, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func displayView(_ index: Int, frame: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Theme.border))
            // Above the display, since app tiles cover it.
            .overlay(alignment: .topLeading) {
                Text("\(index + 1). \(arrangement.displays[index].identity.name)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(y: -15)
            }
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
    }

    private func tile(_ placement: Placement, rect: CGRect) -> some View {
        let selected = selection == placement.id
        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Theme.accent.opacity(selected ? 0.35 : 0.18))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: selected ? 2 : 1))
            .overlay {
                VStack(spacing: 2) {
                    AppIcon(bundleID: placement.bundleID, size: min(28, rect.height * 0.4))
                    if rect.height > 48 {
                        Text(placement.appName)
                            .font(.caption2)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(2)
            }
            .frame(width: max(rect.width - 4, 8), height: max(rect.height - 4, 8))
            .offset(x: rect.minX + 2, y: rect.minY + 2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(placement.appName), \(placement.area.title)")
    }

    private func drag(_ placement: Placement, rect: CGRect, layout: CanvasLayout) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                dragging = placement.id
                selection = placement.id
                dragOffset = value.translation
            }
            .onEnded { value in
                let drop = CGPoint(x: rect.midX + value.translation.width, y: rect.midY + value.translation.height)
                if let (display, region) = layout.target(at: drop),
                   let index = arrangement.placements.firstIndex(where: { $0.id == placement.id }) {
                    arrangement.placements[index].display = display
                    arrangement.placements[index].area = .region(region)
                }
                dragging = nil
                dragOffset = .zero
            }
    }
}

/// Fits the displays' real frames into the canvas, keeping their relative sizes and positions.
struct CanvasLayout {
    let displays: [DisplayRef]
    let size: CGSize
    private let scale: CGFloat
    private let origin: CGPoint
    private let offset: CGPoint

    init(displays: [DisplayRef], size: CGSize, padding: CGFloat = 22) {
        self.displays = displays
        self.size = size
        let bounds = displays.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else {
            scale = 1
            origin = .zero
            offset = .zero
            return
        }
        scale = min((size.width - 2 * padding) / bounds.width, (size.height - 2 * padding) / bounds.height)
        origin = bounds.origin
        offset = CGPoint(x: (size.width - bounds.width * scale) / 2, y: (size.height - bounds.height * scale) / 2)
    }

    func rect(forDisplay index: Int) -> CGRect {
        let frame = displays[index].frame
        return CGRect(x: offset.x + (frame.minX - origin.x) * scale, y: offset.y + (frame.minY - origin.y) * scale,
                      width: frame.width * scale, height: frame.height * scale).insetBy(dx: 2, dy: 2)
    }

    func rect(for placement: Placement) -> CGRect? {
        guard placement.display < displays.count else { return nil }
        let display = rect(forDisplay: placement.display)
        let unit = placement.area.unitRect ?? UnitRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        return CGRect(x: display.minX + unit.x * display.width, y: display.minY + unit.y * display.height,
                      width: unit.width * display.width, height: unit.height * display.height)
    }

    /// The display and region for a drop point: a 3×3 grid of each display picks corners, halves or the whole.
    func target(at point: CGPoint) -> (Int, Region)? {
        guard let index = displays.indices.first(where: { rect(forDisplay: $0).contains(point) }) else { return nil }
        let display = rect(forDisplay: index)
        let column = min(2, Int((point.x - display.minX) / display.width * 3))
        let row = min(2, Int((point.y - display.minY) / display.height * 3))
        let grid: [[Region]] = [
            [.topLeft, .topHalf, .topRight],
            [.leftHalf, .maximize, .rightHalf],
            [.bottomLeft, .bottomHalf, .bottomRight]
        ]
        return (index, grid[row][column])
    }
}
