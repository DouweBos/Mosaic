// Utilities/HotKeys.swift
// Mosaic
//
// Global shortcuts for every region and display move, recorded in Settings.

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let nextDisplay = Self("nextDisplay", initial: .init(.rightArrow, modifiers: [.control, .option, .command]))
    static let previousDisplay = Self("previousDisplay", initial: .init(.leftArrow, modifiers: [.control, .option, .command]))
    static let restore = Self("restore", initial: .init(.delete, modifiers: [.control, .option]))

    private static let regionKeys: [Region: KeyboardShortcuts.Key] = [
        .leftHalf: .leftArrow, .rightHalf: .rightArrow, .topHalf: .upArrow, .bottomHalf: .downArrow,
        .topLeft: .u, .topRight: .i, .bottomLeft: .j, .bottomRight: .k,
        .firstThird: .d, .centerThird: .f, .lastThird: .g, .firstTwoThirds: .e, .lastTwoThirds: .t,
        .maximize: .return, .center: .c
    ]

    /// One name per region, created once so KeyboardShortcuts registers each a single time.
    static let regions: [Region: KeyboardShortcuts.Name] = Dictionary(uniqueKeysWithValues: Region.allCases.map { region in
        let initial = regionKeys[region].map { KeyboardShortcuts.Shortcut($0, modifiers: [.control, .option]) }
        return (region, Self("region.\(region.rawValue)", initial: initial))
    })
}
