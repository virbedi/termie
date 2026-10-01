import Foundation
import SwiftTerm
import TermieCore

struct ShellLaunch: Equatable {
    var executable: String
    var directory: String
    var environment: [String]
}

@MainActor
@Observable
final class TerminalSession: Identifiable {
    let id = UUID()
    let fallbackName: String

    private(set) var presence: SessionPresence = .idle
    private(set) var automaticTitle: String?
    private(set) var directory: String?
    var pinnedName: String?

    private var monitor = AttentionMonitor()
    private(set) var terminalView: TermieTerminalView
    private(set) var viewGeneration = 0
    private var didStart = false
    private var preparedLaunch: ShellLaunch?
    private var oscObservation: TerminalOscObservation?
    private let outputPing = OutputPing()
    var onNeedsYou: ((String) -> Void)?

    var displayName: String {
        if let pinnedName, !pinnedName.isEmpty { return pinnedName }
        return automaticTitle ?? fallbackName
    }

    var followsTitle: Bool { pinnedName == nil }

    init(ordinal: Int, fontSize: CGFloat) {
        fallbackName = ordinal == 1 ? "Terminal" : "Terminal \(ordinal)"
        terminalView = TermieTerminalView(
            font: .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        )
        wire(terminalView)
    }

    func commitName(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            pinnedName = nil
        } else {
            pinnedName = trimmed
        }
    }

    func followTitle() {
        pinnedName = nil
    }

    func setFocused(_ focused: Bool) {
        record(.focusChanged(focused))
    }

    func noteOutput() {
        record(.output(Date()))
    }

    func tick(_ date: Date) {
        record(.tick(date))
    }

    func close() {
        oscObservation?.cancel()
        oscObservation = nil
        terminalView.terminate()
    }

    func prepare(_ launch: ShellLaunch) {
        preparedLaunch = launch
    }

    func restart(fontSize: CGFloat, launch: ShellLaunch) {
        oscObservation?.cancel()
        oscObservation = nil
        terminalView.terminate()
        didStart = false
        preparedLaunch = launch
        monitor = AttentionMonitor()
        presence = .idle
        automaticTitle = nil
        let view = TermieTerminalView(
            font: .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        )
        wire(view)
        terminalView = view
        viewGeneration += 1
    }

    func startIfNeeded() {
        guard !didStart, let preparedLaunch else { return }
        begin(preparedLaunch, in: terminalView)
    }

    private func begin(_ launch: ShellLaunch, in view: TermieTerminalView) {
        didStart = true
        directory = launch.directory
        view.processDelegate = self
        oscObservation = view.observeOscEvents { [weak self] event in
            let meaning = interpretOsc(code: event.code, payload: event.payload)
            Task { @MainActor in
                self?.ingest(meaning)
            }
        }
        view.setProcessOutputHandler { [outputPing] in
            outputPing.ping()
        }
        view.startProcess(
            executable: launch.executable,
            args: ["-l"],
            environment: launch.environment,
            execName: nil,
            currentDirectory: launch.directory
        )
    }

    private func wire(_ view: TermieTerminalView) {
        view.setBellHandler { [weak self] in
            self?.record(.bell)
        }
        outputPing.set { [weak self] in
            self?.noteOutput()
        }
    }

    private func ingest(_ meaning: OscMeaning) {
        switch meaning {
        case .title(let title):
            record(.title(title))
        case .notification(let message):
            record(.notification(message))
        case .progress(let kind):
            record(.progress(kind))
        case .shell(let mark):
            record(.shell(mark))
        case .directory(let path):
            directory = path
        case .none:
            break
        }
    }

    private func record(_ event: AttentionEvent) {
        let before = presence
        monitor.reduce(event)
        if presence != monitor.presence {
            presence = monitor.presence
        }
        if automaticTitle != monitor.automaticTitle {
            automaticTitle = monitor.automaticTitle
        }
        if case .needsYou(let reason) = presence {
            if case .needsYou = before {
                return
            }
            onNeedsYou?(reason)
        }
    }
}

extension TerminalSession: LocalProcessTerminalViewDelegate {
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        record(.title(title))
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let directory else { return }
        if directory.hasPrefix("file://"), let url = URL(string: directory), !url.path.isEmpty {
            self.directory = url.path
        } else {
            self.directory = directory
        }
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        record(.exited(exitCode ?? -1))
    }

    func processFailedToStart(source: TerminalView, error: LocalProcessError) {
        record(.exited(-1))
    }
}
