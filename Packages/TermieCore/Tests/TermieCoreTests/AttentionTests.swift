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

