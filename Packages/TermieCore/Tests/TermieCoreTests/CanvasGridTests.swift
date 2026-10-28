import Testing
@testable import TermieCore

@Test func equalGridUsesOneCellForASingleTile() {
    let frames = equalGridFrames(count: 1)
    #expect(frames == [UnitRect(x: 0, y: 0, width: 1, height: 1)])
}

@Test func twoTilesSplitTheCanvasEvenly() {
    let frames = equalGridFrames(count: 2)
    #expect(frames.count == 2)
    #expect(frames[0] == UnitRect(x: 0, y: 0, width: 0.5, height: 1))
    #expect(frames[1] == UnitRect(x: 0.5, y: 0, width: 0.5, height: 1))
}

@Test func threeTilesStayEqualWithAnEmptySlot() {
    #expect(canvasColumnCount(for: 3) == 2)
    let frames = equalGridFrames(count: 3)
    #expect(frames.count == 3)
    #expect(frames[0] == UnitRect(x: 0, y: 0, width: 0.5, height: 0.5))
    #expect(frames[1] == UnitRect(x: 0.5, y: 0, width: 0.5, height: 0.5))
    #expect(frames[2] == UnitRect(x: 0, y: 0.5, width: 0.5, height: 0.5))
    #expect(frames.allSatisfy { abs($0.width - 0.5) < 0.000_001 && abs($0.height - 0.5) < 0.000_001 })
}

@Test func fourTilesFillASquare() {
    let frames = equalGridFrames(count: 4)
    #expect(frames[0] == UnitRect(x: 0, y: 0, width: 0.5, height: 0.5))
    #expect(frames[3] == UnitRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
}

@Test func reorderMovesAVisibleTileAndKeepsHiddenOnesParked() {
    let all = ["a", "b", "c", "d"]
    let hidden: Set = ["b"]
    let moved = reorderPreservingHidden(all: all, hidden: hidden, moving: "c", before: "a")
    #expect(moved == ["c", "b", "a", "d"])
}

@Test func reorderToEndAppendsAmongVisibleTiles() {
    let all = ["a", "b", "c"]
    let moved = reorderPreservingHidden(all: all, hidden: [], moving: "a", before: nil)
    #expect(moved == ["b", "c", "a"])
}

@Test func droppingOnATileSelectsThatSlot() {
    let frames = equalGridFrames(count: 4)
    let slot = canvasDropSlot(frames: frames, at: CanvasPoint(x: 0.75, y: 0.75), moving: 0)
    #expect(slot == 3)
}

@Test func droppingOutsideTheCanvasLandsOnTheNearestTile() {
    let frames = equalGridFrames(count: 2)
    let slot = canvasDropSlot(frames: frames, at: CanvasPoint(x: 1.4, y: 0.2), moving: 0)
    #expect(slot == 1)
}

@Test func occupyingASlotShiftsTheOthersAndParksHiddenSessions() {
    let all = ["a", "b", "c", "d"]
    let moved = reorderOccupyingSlot(all: all, hidden: ["b"], moving: "d", toSlot: 0)
    #expect(moved == ["d", "b", "a", "c"])
}

@Test func occupyingTheSameSlotLeavesOrderAlone() {
    let all = ["a", "b", "c"]
    #expect(reorderOccupyingSlot(all: all, hidden: [], moving: "b", toSlot: 1) == all)
    #expect(reorderOccupyingSlot(all: all, hidden: ["a"], moving: "a", toSlot: 0) == all)
}

@Test func reorderIgnoresHiddenOrUnknownDestinations() {
    let all = ["a", "b", "c"]
    #expect(reorderPreservingHidden(all: all, hidden: ["b"], moving: "a", before: "b") == all)
    #expect(reorderPreservingHidden(all: all, hidden: [], moving: "a", before: "z") == all)
    #expect(reorderPreservingHidden(all: all, hidden: ["a"], moving: "a", before: "c") == all)
}

@Test func shellThemeCyclesThroughLightDarkAndTheThreeColors() {
    #expect(ShellTheme.allCases == [.dark, .light, .blue, .gray, .green])
    var theme = ShellTheme.dark
    theme.cycle()
    #expect(theme == .light)
    theme.cycle()
    #expect(theme == .blue)
    theme.cycle()
    #expect(theme == .gray)
    theme.cycle()
    #expect(theme == .green)
    theme.cycle()
    #expect(theme == .dark)
    #expect(ShellTheme.dark.nextTitle == "Light")
    #expect(ShellTheme.green.nextTitle == "Dark")
    #expect(ShellTheme.light.prefersLightInterface)
    #expect(!ShellTheme.blue.prefersLightInterface)
    #expect(ShellTheme.blue.swatch == ThemeColor(red: 0.12, green: 0.28, blue: 0.55))
    #expect(ShellTheme.gray.swatch == ThemeColor(red: 0.45, green: 0.46, blue: 0.48))
    #expect(ShellTheme.green.swatch == ThemeColor(red: 0.10, green: 0.38, blue: 0.24))
}
