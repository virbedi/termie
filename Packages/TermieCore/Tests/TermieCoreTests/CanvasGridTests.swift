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

@Test func reorderIgnoresHiddenOrUnknownDestinations() {
    let all = ["a", "b", "c"]
    #expect(reorderPreservingHidden(all: all, hidden: ["b"], moving: "a", before: "b") == all)
    #expect(reorderPreservingHidden(all: all, hidden: [], moving: "a", before: "z") == all)
    #expect(reorderPreservingHidden(all: all, hidden: ["a"], moving: "a", before: "c") == all)
}

@Test func shellThemeTogglesBetweenDarkAndLight() {
    var theme = ShellTheme.dark
    theme.toggle()
    #expect(theme == .light)
    theme.toggle()
    #expect(theme == .dark)
    #expect(ShellTheme.dark.oppositeTitle == "Light")
    #expect(ShellTheme.light.oppositeTitle == "Dark")
}
