import Foundation

/// Wraps one filesystem path so a shell treats it as a single argument.
public func shellQuotedPath(_ path: String) -> String {
    "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

/// Text to send when files are dropped on a terminal: quoted paths separated by spaces, with no newline.
public func shellDropText(paths: [String]) -> String {
    paths.filter { !$0.isEmpty }.map(shellQuotedPath).joined(separator: " ")
}
