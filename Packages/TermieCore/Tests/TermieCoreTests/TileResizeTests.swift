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

@Test func shrinkingAWindowLeavesTheOthersInPlace() {
    let frames = equalGridFrames(count: 2)
    let resized = resizeTileEdge(frames, at: 0, edge: .right, to: 0.3, minimum: 0.1)
    #expect(abs(resized[0].width - 0.3) < 0.000_001)
    #expect(resized[1] == frames[1])
}

@Test func coveringAWindowShrinksItDownToTheMinimum() {
    let frames = equalGridFrames(count: 2)
    let resized = resizeTileEdge(frames, at: 0, edge: .right, to: 0.7, minimum: 0.1)
    #expect(abs(resized[0].width - 0.7) < 0.000_001)
    #expect(abs(resized[1].x - 0.7) < 0.000_001)
    #expect(abs(resized[1].width - 0.3) < 0.000_001)
    #expect(!resized[0].intersects(resized[1]))

    let swallowed = resizeTileEdge(frames, at: 0, edge: .right, to: 1, minimum: 0.2)
    #expect(abs(swallowed[1].width - 0.2) < 0.000_001)
    #expect(abs(swallowed[1].x - 0.8) < 0.000_001)
    #expect(abs(swallowed[0].width - 0.8) < 0.000_001)
    #expect(!swallowed[0].intersects(swallowed[1]))
}

@Test func anOuterEdgeResizesOnlyThatWindow() {
    let frames = equalGridFrames(count: 2)
    let resized = resizeTileEdge(frames, at: 0, edge: .left, to: 0.2, minimum: 0.1)
    #expect(abs(resized[0].x - 0.2) < 0.000_001)
    #expect(abs(resized[0].width - 0.3) < 0.000_001)
    #expect(resized[1] == frames[1])
}

@Test func aWindowEdgeStopsAtTheCanvasAndTheMinimumSize() {
    let frames = equalGridFrames(count: 2)
    let shrunk = resizeTileEdge(frames, at: 0, edge: .right, to: 0.01, minimum: 0.2)
    #expect(abs(shrunk[0].width - 0.2) < 0.000_001)
    let expanded = resizeTileEdge(frames, at: 0, edge: .right, to: 1.4, minimum: 0.1)
    #expect(abs(expanded[1].width - 0.1) < 0.000_001)
    #expect(!expanded[0].intersects(expanded[1]))
}

@Test func resizingACornerLeavesTheOtherWindowsInPlace() {
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
    #expect(resized[2] == frames[2])
    #expect(resized[3] == frames[3])
    #expect(!resized[0].intersects(resized[1]))
}

@Test func anOuterCornerResizesOnlyThatWindow() {
    let frames = equalGridFrames(count: 4)
    let resized = resizeTileCorner(
        frames,
        at: 0,
        corner: .topLeft,
        toX: 0.2,
        toY: 0.2,
        minimum: 0.1
    )
    #expect(abs(resized[0].x - 0.2) < 0.000_001)
    #expect(abs(resized[0].y - 0.2) < 0.000_001)
    #expect(abs(resized[0].width - 0.3) < 0.000_001)
    #expect(abs(resized[0].height - 0.3) < 0.000_001)
    #expect(resized.dropFirst().elementsEqual(frames.dropFirst()))
}

@Test func aCornerMovesBothEdgesOfThatWindowOnly() {
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
    #expect(abs(resized[0].y - 0.2) < 0.000_001)
    #expect(abs(resized[0].height - 0.8) < 0.000_001)
    #expect(abs(resized[1].x - 0.65) < 0.000_001)
    #expect(abs(resized[1].width - 0.35) < 0.000_001)
    #expect(!resized[0].intersects(resized[1]))
}
