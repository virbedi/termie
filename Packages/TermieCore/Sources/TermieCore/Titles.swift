import Foundation

/// Turns a raw terminal title into the name shown on a session.
/// Shells often publish their own binary name; those are ignored so a later
/// task title (the one Claude writes into iTerm) can take the slot.
public func automaticSessionTitle(from raw: String) -> String? {
    let ornaments = CharacterSet(charactersIn: "✳✱✻✶※*•·")
    let trimmed = raw
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: ornaments)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let boring: Set<String> = [
        "zsh", "bash", "fish", "sh", "login",
        "-zsh", "-bash", "-fish", "terminal",
    ]
    if boring.contains(trimmed.lowercased()) { return nil }
    return trimmed
}
