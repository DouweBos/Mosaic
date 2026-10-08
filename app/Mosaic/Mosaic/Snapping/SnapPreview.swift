// Snapping/SnapPreview.swift
// Mosaic
//
// The translucent outline showing where a dragged window will land.

import AppKit
import SwiftUI

final class SnapPreview {
    private lazy var panel: NSPanel = {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: SnapPreviewShape())
        hosting.sizingOptions = []
        panel.contentView = hosting
        return panel
    }()

    private var shown: CGRect?

    /// Shows the outline at a frame in accessibility space.
    func show(_ frame: CGRect) {
        guard frame != shown, let mainHeight = NSScreen.screens.first?.frame.height else { return }
        let cocoa = Geometry.flip(frame, mainHeight: mainHeight)
        if shown == nil {
            panel.setFrame(cocoa, display: true)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { $0.duration = 0.12; panel.animator().alphaValue = 1 }
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().setFrame(cocoa, display: true)
            }
        }
        shown = frame
    }

    func hide() {
        guard shown != nil else { return }
        shown = nil
        panel.orderOut(nil)
    }
}

private struct SnapPreviewShape: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Theme.accent.opacity(0.18))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.accent, lineWidth: 2))
            .padding(4)
    }
}
