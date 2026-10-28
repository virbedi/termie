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

    private(set) var presence: SessionPresence = .running
    private(set) var automaticTitle: String?
    private(set) var directory: String?
    var pinnedName: String?
    /// Per-tile shell chrome and SwiftTerm colors. Independent of other tiles.
    var theme: ShellTheme = .dark
    /// Last grid size, so a minimized shell keeps its rows and columns.
    var parkedSize = CGSize(width: 640, height: 400)

    private(set) var terminalView: TermieTerminalView
    private(set) var viewGeneration = 0
    private var didStart = false
    private var preparedLaunch: ShellLaunch?
    private var oscObservation: TerminalOscObservation?

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
        presence = .running
        automaticTitle = nil
        let view = TermieTerminalView(
            font: .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        )
        wire(view)
        terminalView = view
        viewGeneration += 1
        // Theme is reapplied by TerminalHost after the new view is hosted.
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
        view.startProcess(
            executable: launch.executable,
            args: ["-l"],
            environment: launch.environment,
            execName: nil,
            currentDirectory: launch.directory
        )
    }

    private func wire(_ view: TermieTerminalView) {
        view.onUsableSize = { [weak self] in
            self?.startIfNeeded()
        }
    }

    private func ingest(_ meaning: OscMeaning) {
        switch meaning {
        case .title(let title):
            noteTitle(title)
        case .directory(let path):
            directory = path
        case .notification, .progress, .shell, .none:
            break
        }
    }

    private func noteTitle(_ raw: String) {
        if let title = automaticSessionTitle(from: raw) {
            automaticTitle = title
        }
    }

    private func noteExit(_ code: Int32) {
        presence = .exited(code)
    }
}

extension TerminalSession: LocalProcessTerminalViewDelegate {
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        noteTitle(title)
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
        noteExit(exitCode ?? -1)
    }

    func processFailedToStart(source: TerminalView, error: LocalProcessError) {
        noteExit(-1)
    }
}
