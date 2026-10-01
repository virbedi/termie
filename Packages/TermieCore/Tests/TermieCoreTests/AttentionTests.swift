import Foundation
import Testing
@testable import TermieCore

@Test func shellTitlesAreIgnoredAndTaskTitlesAreKept() {
    #expect(automaticSessionTitle(from: "  zsh ") == nil)
    #expect(automaticSessionTitle(from: "✳ fix auth") == "fix auth")
    #expect(automaticSessionTitle(from: "Review the migration") == "Review the migration")
}

@Test func osc9NotificationAndProgressAreDistinct() {
    #expect(interpretOsc(code: 9, payload: Array("Claude needs your permission".utf8)) == .notification("Claude needs your permission"))
    #expect(interpretOsc(code: 9, payload: Array("4;3;".utf8)) == .progress(.indeterminate))
    #expect(interpretOsc(code: 9, payload: Array("4;1;40".utf8)) == .progress(.set(40)))
    #expect(interpretOsc(code: 9, payload: Array("4;0".utf8)) == .progress(.remove))
    #expect(interpretOsc(code: 0, payload: Array("rename the client".utf8)) == .title("rename the client"))
    #expect(interpretOsc(code: 777, payload: Array("notify;Claude;Turn finished".utf8)) == .notification("Claude — Turn finished"))
    #expect(interpretOsc(code: 133, payload: Array("C".utf8)) == .shell(.commandStart))
    #expect(interpretOsc(code: 7, payload: Array("file://localhost/Users/me/dev".utf8)) == .directory("/Users/me/dev"))
}

@Test func outputThenQuietReturnsToIdle() {
    var monitor = AttentionMonitor()
    let start = Date(timeIntervalSince1970: 1_000)
    monitor.reduce(.output(start))
    #expect(monitor.presence == .working)
    monitor.reduce(.tick(start.addingTimeInterval(0.2)))
    #expect(monitor.presence == .working)
    monitor.reduce(.tick(start.addingTimeInterval(AttentionMonitor.quietAfter)))
    #expect(monitor.presence == .idle)
}

@Test func bellSticksUntilTheSessionIsFocused() {
    var monitor = AttentionMonitor()
    let start = Date()
    monitor.reduce(.output(start))
    monitor.reduce(.bell)
    monitor.reduce(.output(start.addingTimeInterval(0.1)))
    #expect(monitor.presence == .needsYou(reason: "Needs you"))
    monitor.reduce(.focusChanged(true))
    #expect(monitor.presence == .working)
}

@Test func progressClearOnABackgroundSessionNeedsInput() {
    var monitor = AttentionMonitor()
    monitor.reduce(.progress(.indeterminate))
    #expect(monitor.presence == .working)
    monitor.reduce(.progress(.remove))
    #expect(monitor.presence == .needsYou(reason: "Ready for input"))
    monitor.reduce(.progress(.indeterminate))
    #expect(monitor.presence == .working)
}

@Test func titlesUpdateTheAutomaticName() {
    var monitor = AttentionMonitor()
    monitor.reduce(.title("zsh"))
    #expect(monitor.automaticTitle == nil)
    monitor.reduce(.title("✳ wire up sessions"))
    #expect(monitor.automaticTitle == "wire up sessions")
}

@Test func bentoGivesTheEmphasizedSessionTheLargeCell() {
    let frames = bentoFrames(count: 3, emphasis: 2, wide: true)
    #expect(frames.count == 3)
    #expect(frames[2].width > frames[0].width)
    #expect(frames[2].height == 1)
}

@Test func fourAndTwoLayoutsStayInsideTheSquare() {
    let four = bentoFrames(count: 4, emphasis: 0, wide: true)
    #expect(four[0] == UnitRect(x: 0, y: 0, width: 0.62, height: 0.62))
    let pair = bentoFrames(count: 2, emphasis: 0, wide: false)
    #expect(pair[1].y == 0.5)
    let single = bentoFrames(count: 1, emphasis: 0, wide: true)
    #expect(single[0] == UnitRect(x: 0, y: 0, width: 1, height: 1))
}
