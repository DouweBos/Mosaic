// GeometryTests.swift
// MosaicTests
//
// Region frames, gaps, coordinate flips and recognizing a layout from window frames.

import CoreGraphics
import Testing
@testable import Mosaic

struct GeometryTests {
    private let visible = CGRect(x: 0, y: 25, width: 1440, height: 875)

    @Test func halvesSplitTheUsableArea() {
        #expect(Geometry.frame(for: .region(.leftHalf), in: visible) == CGRect(x: 0, y: 25, width: 720, height: 875))
        #expect(Geometry.frame(for: .region(.rightHalf), in: visible) == CGRect(x: 720, y: 25, width: 720, height: 875))
    }

    @Test func bottomRegionsSitAtTheBottomInAccessibilitySpace() {
        let frame = Geometry.frame(for: .region(.bottomHalf), in: visible)
        #expect(frame.maxY == visible.maxY)
        #expect(frame.minY > visible.minY)
    }

    @Test func gapsAreEvenBetweenNeighbors() {
        let left = Geometry.frame(for: .region(.leftHalf), in: visible, gap: 10)
        let right = Geometry.frame(for: .region(.rightHalf), in: visible, gap: 10)
        #expect(left.minX == 10)
        #expect(right.minX - left.maxX == 10)
        #expect(visible.maxX - right.maxX == 10)
    }

    @Test func centerKeepsTheWindowSize() {
        let current = CGRect(x: 5, y: 40, width: 800, height: 600)
        let frame = Geometry.frame(for: .region(.center), in: visible, current: current)
        #expect(frame.size == current.size)
        #expect(abs(frame.midX - visible.midX) <= 1)
    }

    @Test func flippingMatchesTheMainDisplay() {
        let cocoa = CGRect(x: 0, y: 0, width: 1440, height: 875)
        #expect(Geometry.flip(cocoa, mainHeight: 900) == CGRect(x: 0, y: 25, width: 1440, height: 875))
    }

    @Test func nearbyFramesMatchTheirPreset() {
        let almostLeft = CGRect(x: 3, y: 30, width: 714, height: 868)
        #expect(Geometry.area(matching: almostLeft, in: visible) == .region(.leftHalf))
    }

    @Test func oddFramesStayCustom() {
        let odd = CGRect(x: 200, y: 200, width: 500, height: 400)
        guard case .custom(let unit) = Geometry.area(matching: odd, in: visible) else {
            Issue.record("expected a custom area")
            return
        }
        let back = Geometry.frame(for: .custom(unit), in: visible)
        #expect(abs(back.minX - odd.minX) <= 1 && abs(back.width - odd.width) <= 1)
    }

    @Test func windowsBelongToTheDisplayHoldingMostOfThem() {
        let displays = [CGRect(x: 0, y: 0, width: 1000, height: 800), CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        #expect(Geometry.bestMatch(for: CGRect(x: 900, y: 0, width: 400, height: 300), among: displays) == 1)
        #expect(Geometry.bestMatch(for: CGRect(x: 5000, y: 0, width: 10, height: 10), among: displays) == 1)
    }
}
