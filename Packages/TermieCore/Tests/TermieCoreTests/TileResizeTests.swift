import Testing
@testable import TermieCore

@Test func twoColumnsShareOneVerticalDivider() {
    let frames = bentoFrames(count: 2, emphasis: 0, wide: true)
    let dividers = tileDividers(in: frames)
    #expect(dividers == [TileDivider(axis: .vertical, position: 0.5, start: 0, end: 1)])
}

@Test func draggingAColumnDividerGivesWidthToTheLeftTile() {
    let frames = bentoFrames(count: 2, emphasis: 0, wide: true)
    let divider = tileDividers(in: frames)[0]
    let resized = resizeTiles(frames, divider: divider, to: 0.7)
    #expect(abs(resized[0].width - 0.7) < 0.000_001)
    #expect(abs(resized[1].x - 0.7) < 0.000_001)
    #expect(abs(resized[1].width - 0.3) < 0.000_001)
}

@Test func aDividerStopsBeforeATileShrinksBelowTheMinimum() {
    let frames = bentoFrames(count: 2, emphasis: 0, wide: true)
    let divider = tileDividers(in: frames)[0]
    let resized = resizeTiles(frames, divider: divider, to: 0.99, minimum: 0.2)
    #expect(abs(resized[0].width - 0.8) < 0.000_001)
    #expect(abs(resized[1].width - 0.2) < 0.000_001)
}

@Test func aStackSeamResizesEveryTileOnThatLine() {
    let frames = bentoFrames(count: 3, emphasis: 0, wide: true)
    let dividers = tileDividers(in: frames)
    let vertical = dividers.first { $0.axis == .vertical }
    let horizontal = dividers.first { $0.axis == .horizontal }
    #expect(vertical == TileDivider(axis: .vertical, position: 0.62, start: 0, end: 1))
    #expect(horizontal == TileDivider(axis: .horizontal, position: 0.5, start: 0.62, end: 1))

    let resized = resizeTiles(frames, divider: vertical!, to: 0.4, minimum: 0.1)
    #expect(resized[0].width == 0.4)
    #expect(resized[1].x == 0.4)
    #expect(resized[2].x == 0.4)
    #expect(resized[1].y == 0)
    #expect(resized[2].y == 0.5)

    let stacked = resizeTiles(frames, divider: horizontal!, to: 0.25, minimum: 0.1)
    #expect(stacked[0] == frames[0])
    #expect(stacked[1].height == 0.25)
    #expect(stacked[2].y == 0.25)
}

@Test func fourTilesShareACrossOfDividers() {
    let frames = bentoFrames(count: 4, emphasis: 0, wide: true)
    let dividers = tileDividers(in: frames)
    #expect(dividers.count == 2)
    #expect(dividers.contains(TileDivider(axis: .vertical, position: 0.62, start: 0, end: 1)))
    #expect(dividers.contains(TileDivider(axis: .horizontal, position: 0.62, start: 0, end: 1)))
}
