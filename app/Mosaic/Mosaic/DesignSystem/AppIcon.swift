// DesignSystem/AppIcon.swift
// Mosaic
//
// An app's icon by bundle identifier, with a generic one for apps that aren't installed.

import AppKit
import SwiftUI

struct AppIcon: View {
    let bundleID: String
    var size: CGFloat = 20

    var body: some View {
        Image(nsImage: Self.image(for: bundleID))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    static func image(for bundleID: String) -> NSImage {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil) ?? NSImage()
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

#Preview {
    HStack { AppIcon(bundleID: "com.apple.finder", size: 32); AppIcon(bundleID: "com.example.missing", size: 32) }
        .padding()
}
