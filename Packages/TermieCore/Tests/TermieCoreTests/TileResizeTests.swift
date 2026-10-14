import Testing
@testable import TermieCore

@Test func twoColumnsShareOneVerticalDivider() {
    let frames = equalGridFrames(count: 2)
    let dividers = tileDividers(in: frames)
    #expect(dividers == [TileDivider(axis: .vertical, position: 0.5, start: 0, end: 1)])
}

@Test func draggingAColumnDividerGivesWidthToTheLeftTile() {
    let frames = equalGridFrames(count: 2)
    let divider = tileDividers(in: frames)[0]
    let resized = resizeTiles(frames, divider: divider, to: 0.7)
    #expect(abs(resized[0].width - 0.7) < 0.000_001)
    #expect(abs(resized[1].x - 0.7) < 0.000_001)
    #expect(abs(resized[1].width - 0.3) < 0.000_001)
}

@Test func aDividerStopsBeforeATileShrinksBelowTheMinimum() {
    let frames = equalGridFrames(count: 2)
    let divider = tileDividers(in: frames)[0]
    let resized = resizeTiles(frames, divider: divider, to: 0.99, minimum: 0.2)
    #expect(abs(resized[0].width - 0.8) < 0.000_001)
    #expect(abs(resized[1].width - 0.2) < 0.000_001)
}

@Test func threeTileCanvasKeepsIndependentSeams() {
    let frames = equalGridFrames(count: 3)
    let dividers = tileDividers(in: frames)
    let vertical = dividers.first { $0.axis == .vertical }
    let horizontal = dividers.first { $0.axis == .horizontal }
    #expect(vertical == TileDivider(axis: .vertical, position: 0.5, start: 0, end: 0.5))
    #expect(horizontal == TileDivider(axis: .horizontal, position: 0.5, start: 0, end: 0.5))

    let resized = resizeTiles(frames, divider: vertical!, to: 0.35, minimum: 0.1)
    #expect(abs(resized[0].width - 0.35) < 0.000_001)
    #expect(abs(resized[1].x - 0.35) < 0.000_001)
    #expect(resized[2] == frames[2])

    let stacked = resizeTiles(frames, divider: horizontal!, to: 0.3, minimum: 0.1)
    #expect(stacked[1] == frames[1])
    #expect(abs(stacked[0].height - 0.3) < 0.000_001)
    #expect(abs(stacked[2].y - 0.3) < 0.000_001)
}

@Test func fourTilesShareACrossOfDividers() {
    let frames = equalGridFrames(count: 4)
    let dividers = tileDividers(in: frames)
    #expect(dividers.count == 2)
    #expect(dividers.contains(TileDivider(axis: .vertical, position: 0.5, start: 0, end: 1)))
    #expect(dividers.contains(TileDivider(axis: .horizontal, position: 0.5, start: 0, end: 1)))
}

@Test func draggingACornerResizesNeighborsOnBothAxes() {
    let frames = equalGridFrames(count: 4)
    let resized = resizeTileCorner(
        frames,
        at: 0,
        corner: .bottomRight,
        toX: 0.7,
        toY: 0.3,
        minimum: 0.1
    )
    #expect(abs(resized[0].width - 0.7) < 0.000_001)
    #expect(abs(resized[0].height - 0.3) < 0.000_001)
    #expect(abs(resized[1].x - 0.7) < 0.000_001)
    #expect(abs(resized[1].width - 0.3) < 0.000_001)
    #expect(abs(resized[1].height - 0.3) < 0.000_001)
    #expect(abs(resized[2].y - 0.3) < 0.000_001)
    #expect(abs(resized[2].width - 0.7) < 0.000_001)
    #expect(abs(resized[2].height - 0.7) < 0.000_001)
    #expect(abs(resized[3].x - 0.7) < 0.000_001)
    #expect(abs(resized[3].y - 0.3) < 0.000_001)
    #expect(abs(resized[3].width - 0.3) < 0.000_001)
    #expect(abs(resized[3].height - 0.7) < 0.000_001)
}

@Test func anOuterCornerWithoutNeighborsDoesNotOpenAGap() {
    let frames = equalGridFrames(count: 4)
    let resized = resizeTileCorner(
        frames,
        at: 0,
        corner: .topLeft,
        toX: 0.2,
        toY: 0.2,
        minimum: 0.1
    )
    #expect(resized == frames)
}

@Test func aCornerOnOneSharedEdgeOnlyMovesThatAxis() {
    let frames = equalGridFrames(count: 2)
    let resized = resizeTileCorner(
        frames,
        at: 0,
        corner: .topRight,
        toX: 0.65,
        toY: 0.2,
        minimum: 0.1
    )
    #expect(abs(resized[0].width - 0.65) < 0.000_001)
    #expect(resized[0].y == 0)
    #expect(resized[0].height == 1)
    #expect(abs(resized[1].x - 0.65) < 0.000_001)
}
