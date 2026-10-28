import Testing
@testable import TermieCore

@Test func aPlainPathIsSingleQuoted() {
    #expect(shellDropText(paths: ["/tmp/shot.png"]) == "'/tmp/shot.png'")
}

@Test func spacesAndQuotesStayOneArgument() {
    #expect(shellQuotedPath("/Users/me/My File.txt") == "'/Users/me/My File.txt'")
    #expect(shellQuotedPath("/tmp/it's.png") == "'/tmp/it'\\''s.png'")
}

@Test func severalDroppedPathsAreSeparatedBySpaces() {
    let text = shellDropText(paths: ["/a/b", "/c d"])
    #expect(text == "'/a/b' '/c d'")
}

@Test func emptyPathsAreLeftOut() {
    #expect(shellDropText(paths: ["", "/tmp/a"]) == "'/tmp/a'")
    #expect(shellDropText(paths: []) == "")
}
