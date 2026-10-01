import Foundation

public enum SessionPresence: Equatable, Sendable {
    case idle
    case working
    case needsYou(reason: String)
    case exited(Int32)
}

public enum AttentionEvent: Equatable, Sendable {
    case output(Date)
    case title(String)
    case bell
    case notification(String)
    case progress(ProgressKind)
    case shell(ShellMark)
    case focusChanged(Bool)
    case tick(Date)
    case exited(Int32)
}

public struct AttentionMonitor: Equatable, Sendable {
    public static let quietAfter: TimeInterval = 0.75

    public private(set) var presence: SessionPresence
    public private(set) var automaticTitle: String?
    public private(set) var isFocused: Bool

    private var lastOutput: Date?
    private var progressActive: Bool

    public init() {
        presence = .idle
        automaticTitle = nil
        isFocused = false
        lastOutput = nil
        progressActive = false
    }

    public mutating func reduce(_ event: AttentionEvent) {
        if case .exited(let code) = presence, case .exited = event {
            presence = .exited(code)
            return
        }
        switch event {
        case .output(let date):
            guard !isExited else { return }
            lastOutput = date
            if case .needsYou = presence { return }
            presence = .working
        case .title(let raw):
            if let title = automaticSessionTitle(from: raw) {
                automaticTitle = title
            }
        case .bell:
            guard !isExited else { return }
            presence = .needsYou(reason: "Needs you")
        case .notification(let message):
            guard !isExited else { return }
            let reason = message.trimmingCharacters(in: .whitespacesAndNewlines)
            presence = .needsYou(reason: reason.isEmpty ? "Needs you" : reason)
        case .progress(let kind):
            guard !isExited else { return }
            apply(progress: kind)
        case .shell(let mark):
            guard !isExited else { return }
            apply(shell: mark)
        case .focusChanged(let focused):
            isFocused = focused
            if focused, case .needsYou = presence {
                presence = progressActive || isRecent(at: Date()) ? .working : .idle
            }
        case .tick(let date):
            guard case .working = presence, !progressActive else { return }
            guard let lastOutput, date.timeIntervalSince(lastOutput) >= Self.quietAfter else { return }
            presence = .idle
        case .exited(let code):
            progressActive = false
            presence = .exited(code)
        }
    }

    private var isExited: Bool {
        if case .exited = presence { return true }
        return false
    }

    private func isRecent(at date: Date) -> Bool {
        guard let lastOutput else { return false }
        return date.timeIntervalSince(lastOutput) < Self.quietAfter
    }

    private mutating func apply(progress kind: ProgressKind) {
        switch kind {
        case .set, .indeterminate:
            progressActive = true
            presence = .working
        case .error:
            progressActive = false
            presence = .needsYou(reason: "Reported an error")
        case .pause:
            progressActive = false
            presence = .needsYou(reason: "Paused")
        case .remove:
            let wasActive = progressActive
            progressActive = false
            guard wasActive else { return }
            presence = isFocused ? .idle : .needsYou(reason: "Ready for input")
        }
    }

    private mutating func apply(shell mark: ShellMark) {
        switch mark {
        case .commandStart:
            presence = .working
        case .prompt, .commandEnd:
            if case .needsYou = presence { return }
            if progressActive { return }
            presence = .idle
        }
    }
}
