// ArrangementTests.swift
// MosaicTests
//
// Recognizing display sets, mapping arrangements onto connected displays, and saving them.

import CoreGraphics
import Foundation
import Testing
@testable import Mosaic

@MainActor
struct ArrangementTests {
    private func ref(_ serial: UInt32, ordinal: Int = 0, x: CGFloat = 0, builtin: Bool = false) -> DisplayRef {
        DisplayRef(identity: DisplayIdentity(vendor: 1, model: 2, serial: serial, isBuiltin: builtin, name: "Display \(serial)"),
                   ordinal: ordinal, frame: CGRect(x: x, y: 0, width: 1000, height: 800))
    }

    private func display(_ ref: DisplayRef) -> Display {
        Display(id: CGDirectDisplayID(ref.identity.serial), ref: ref, frame: ref.frame, visibleFrame: ref.frame)
    }

    @Test func signatureIgnoresOrder() {
        #expect(Arrangement.signature(of: [ref(1), ref(2)]) == Arrangement.signature(of: [ref(2), ref(1)]))
        #expect(Arrangement.signature(of: [ref(1)]) != Arrangement.signature(of: [ref(1), ref(2)]))
    }

    @Test func resolvingFindsTheSameMonitorsWhereverTheyAre() {
        let saved = [ref(1, x: 0), ref(2, x: 1000)]
        let connected = [display(ref(2, x: 0)), display(ref(1, x: 1000))]
        let resolved = DisplayCatalog.resolve(saved, in: connected)
        #expect(resolved.map { $0?.ref.identity.serial } == [1, 2])
    }

    @Test func missingMonitorsFallBackToTheRemainingDisplays() {
        let saved = [ref(1), ref(9)]
        let connected = [display(ref(1)), display(ref(3, x: 1000))]
        #expect(DisplayCatalog.resolve(saved, in: connected).map { $0?.ref.identity.serial } == [1, 3])
    }

    @Test func storeKeepsArrangementsAcrossLaunches() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("MosaicTests-\(UUID().uuidString)")
        let store = ArrangementStore(storage: Storage(root: root))
        let arrangement = Arrangement(name: "Dock", displays: [ref(1), ref(2)], placements: [
            Placement(bundleID: "com.spotify.client", appName: "Spotify", display: 0, area: .region(.maximize)),
            Placement(bundleID: "com.tinyspeck.slackmacgap", appName: "Slack", display: 1, area: .region(.leftHalf))
        ])
        store.add(arrangement)
        let reopened = ArrangementStore(storage: Storage(root: root))
        #expect(reopened.arrangements == [arrangement])
        #expect(reopened.automatic(for: arrangement.displaySignature)?.id == arrangement.id)
    }

    @Test func manualArrangementsDontApplyThemselves() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("MosaicTests-\(UUID().uuidString)")
        let store = ArrangementStore(storage: Storage(root: root))
        var arrangement = Arrangement(name: "Manual", displays: [ref(1)], placements: [])
        arrangement.appliesAutomatically = false
        store.add(arrangement)
        #expect(store.automatic(for: arrangement.displaySignature) == nil)
    }

    @Test func newNamesDontCollide() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("MosaicTests-\(UUID().uuidString)")
        let store = ArrangementStore(storage: Storage(root: root))
        store.add(Arrangement(name: "Layout", displays: [], placements: []))
        store.add(Arrangement(name: "Layout 2", displays: [], placements: []))
        #expect(store.uniqueName("Layout") == "Layout 3")
    }

    @Test func canvasDropsPickRegionsFromAGrid() {
        let layout = CanvasLayout(displays: [ref(1, x: 0), ref(2, x: 1000)], size: CGSize(width: 432, height: 200))
        let second = layout.rect(forDisplay: 1)
        let target = layout.target(at: CGPoint(x: second.minX + 5, y: second.midY))
        #expect(target?.0 == 1)
        #expect(target?.1 == .leftHalf)
        #expect(layout.target(at: CGPoint(x: second.midX, y: second.midY))?.1 == .maximize)
    }
}
