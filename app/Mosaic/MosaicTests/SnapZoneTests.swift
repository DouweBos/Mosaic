// SnapZoneTests.swift
// MosaicTests
//
// Which region a drag to the screen edge picks.

import CoreGraphics
import Testing
@testable import Mosaic

struct SnapZoneTests {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test(arguments: [
        (CGPoint(x: 0, y: 450), Region.leftHalf),
        (CGPoint(x: 1439, y: 450), Region.rightHalf),
        (CGPoint(x: 720, y: 0), Region.maximize),
        (CGPoint(x: 0, y: 10), Region.topLeft),
        (CGPoint(x: 1439, y: 899), Region.bottomRight),
        (CGPoint(x: 300, y: 899), Region.firstThird),
        (CGPoint(x: 720, y: 899), Region.centerThird),
        (CGPoint(x: 1200, y: 899), Region.lastThird)
    ])
    func edgesPickRegions(point: CGPoint, region: Region) {
        #expect(SnapZones.region(at: point, in: screen) == region)
    }

    @Test func awayFromTheEdgesNothingSnaps() {
        #expect(SnapZones.region(at: CGPoint(x: 700, y: 400), in: screen) == nil)
    }

    @Test func secondDisplaysUseTheirOwnEdges() {
        let second = CGRect(x: 1440, y: -200, width: 1920, height: 1080)
        #expect(SnapZones.region(at: CGPoint(x: 1440, y: 300), in: second) == .leftHalf)
    }
}
