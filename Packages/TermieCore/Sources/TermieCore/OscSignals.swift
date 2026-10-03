import Foundation

public enum ProgressKind: Equatable, Sendable {
    case remove
    case set(Int?)
    case error
    case indeterminate
    case pause
}

public enum ShellMark: Equatable, Sendable {
    case prompt
    case commandStart
    case commandEnd
}

public enum OscMeaning: Equatable, Sendable {
    case title(String)
    case notification(String)
    case progress(ProgressKind)
    case shell(ShellMark)
    case directory(String)
    case none
}

public func interpretOsc(code: Int, payload: [UInt8]) -> OscMeaning {
    let text = String(decoding: payload, as: UTF8.self)
    switch code {
    case 0, 1, 2:
        return .title(text)
    case 7:
        return directoryMeaning(from: text)
    case 9:
        if text.hasPrefix("4;") {
            return progressMeaning(from: String(text.dropFirst(2)))
        }
        return notificationMeaning(text)
    case 99:
        return notificationMeaning(text)
    case 133:
        return shellMeaning(from: text)
    case 777:
        return notify777(text)
    default:
        return .none
    }
}

private func notificationMeaning(_ text: String) -> OscMeaning {
    let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !body.isEmpty else { return .notification("Needs you") }
    return .notification(String(body.prefix(180)))
}

private func notify777(_ text: String) -> OscMeaning {
    let parts = text.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
    guard parts.count >= 2, parts[0] == "notify" else {
        return notificationMeaning(text)
    }
    let title = parts.count > 1 ? parts[1] : ""
    let body = parts.count > 2 ? parts[2...].joined(separator: ";") : ""
    let combined = [title, body]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " — ")
    return notificationMeaning(combined.isEmpty ? "Needs you" : combined)
}

private func progressMeaning(from text: String) -> OscMeaning {
    let parts = text.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
    guard let raw = parts.first, let state = Int(raw) else { return .none }
    switch state {
    case 0:
        return .progress(.remove)
    case 1:
        let percent = parts.count > 1 ? Int(parts[1]) : nil
        return .progress(.set(percent))
    case 2:
        return .progress(.error)
    case 3:
        return .progress(.indeterminate)
    case 4:
        return .progress(.pause)
    default:
        return .none
    }
}

private func shellMeaning(from text: String) -> OscMeaning {
    let marker = text.split(separator: ";", maxSplits: 1).first.map(String.init) ?? ""
    switch marker {
    case "A", "B":
        return .shell(.prompt)
    case "C":
        return .shell(.commandStart)
    case "D":
        return .shell(.commandEnd)
    default:
        return .none
    }
}

private func directoryMeaning(from text: String) -> OscMeaning {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .none }
    if trimmed.hasPrefix("file://"), let url = URL(string: trimmed), !url.path.isEmpty {
        return .directory(url.path)
    }
    return .directory(trimmed)
}
