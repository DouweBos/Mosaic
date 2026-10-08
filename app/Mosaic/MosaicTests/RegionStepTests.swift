// RegionStepTests.swift
// MosaicTests
//
// Repeating a shortcut walks a window across displays half a display at a time.

import CoreGraphics
import Testing
@testable import Mosaic

struct RegionStepTests {
    private let laptop = CGRect(x: 0, y: 300, width: 1512, height: 982)
    private let middle = CGRect(x: 1512, y: 0, width: 2560, height: 1440)
    private let right = CGRect(x: 4072, y: 0, width: 2560, height: 1440)
    private var displays: [CGRect] { [laptop, middle, right] }

    @Test func halvesCrossToTheMirroredHalf() {
        #expect(RegionStep.continuation(of: .rightHalf).map { $0.1 } == .leftHalf)
        #expect(RegionStep.continuation(of: .leftHalf).map { $0.1 } == .rightHalf)
        #expect(RegionStep.continuation(of: .topRight).map { $0.1 } == .topLeft)
        #expect(RegionStep.continuation(of: .lastThird).map { $0.1 } == .firstThird)
    }

    @Test func centeredRegionsStayPut() {
        #expect(RegionStep.continuation(of: .maximize) == nil)
        #expect(RegionStep.continuation(of: .centerThird) == nil)
    }

    @Test func neighborsFollowTheDisplayLayout() {
        #expect(RegionStep.neighbor(of: laptop, toward: .right, among: displays) == 1)
        #expect(RegionStep.neighbor(of: middle, toward: .right, among: displays) == 2)
        #expect(RegionStep.neighbor(of: middle, toward: .left, among: displays) == 0)
    }

    @Test func theOutermostDisplayHasNoNeighbor() {
        #expect(RegionStep.neighbor(of: right, toward: .right, among: displays) == nil)
        #expect(RegionStep.neighbor(of: laptop, toward: .left, among: displays) == nil)
    }

    @Test func displaysAboveAndBelowAreFound() {
        let below = CGRect(x: 200, y: 1440, width: 1512, height: 982)
        #expect(RegionStep.neighbor(of: middle, toward: .down, among: [middle, below]) == 1)
        #expect(RegionStep.neighbor(of: below, toward: .up, among: [middle, below]) == 0)
        #expect(RegionStep.neighbor(of: middle, toward: .up, among: [middle, below]) == nil)
    }

    @Test func framesCloseToTheSpotCountAsThere() {
        let target = CGRect(x: 720, y: 25, width: 720, height: 875)
        #expect(RegionStep.isAt(CGRect(x: 722, y: 27, width: 716, height: 871), target))
        #expect(!RegionStep.isAt(CGRect(x: 0, y: 25, width: 720, height: 875), target))
    }
}
