import AppKit
import Observation
import TermieCore

@MainActor
@Observable
final class SessionStore {
    private(set) var sessions: [TerminalSession] = []
    private(set) var minimizedIDs: Set<UUID> = []
    /// Bumped when the canvas should snap back to the equal grid.
    private(set) var layoutEpoch = 0
    var focusedID: UUID?
    var renamingSessionID: UUID?
    private var nextOrdinal = 1
    private var keyMonitor: Any?

    var focusedSession: TerminalSession? {
        sessions.first { $0.id == focusedID }
    }

    var visibleSessions: [TerminalSession] {
        sessions.filter { !minimizedIDs.contains($0.id) }
    }

    var minimizedSessions: [TerminalSession] {
        sessions.filter { minimizedIDs.contains($0.id) }
    }

    var summary: String {
        if let focusedSession {
            return focusedSession.displayName
        }
        return sessions.isEmpty ? "No terminals" : "\(sessions.count) terminals"
    }

    init() {
        NSApp.dockTile.badgeLabel = nil
        let session = makeSession()
        sessions = [session]
        focus(session.id)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.contains(.command),
                  !flags.contains(.shift),
                  event.charactersIgnoringModifiers == "w" else {
                return event
            }
            let shouldClose = MainActor.assumeIsolated { self?.focusedID != nil } ?? false
            guard shouldClose else { return event }
            MainActor.assumeIsolated {
                self?.closeFocused()
            }
            return nil
        }
    }

    func addSession() {
        let session = makeSession()
        sessions.append(session)
        focus(session.id)
    }

    func focus(_ id: UUID) {
        guard let session = sessions.first(where: { $0.id == id }), !minimizedIDs.contains(id) else { return }
        focusedID = session.id
    }

    func minimize(_ id: UUID) {
        guard let session = sessions.first(where: { $0.id == id }), !minimizedIDs.contains(id) else { return }
        let size = session.terminalView.bounds.size
        if size.width > 32, size.height > 32 {
            session.parkedSize = size
        }
        session.terminalView.suppressTinyFrames = true
        let index = sessions.firstIndex(where: { $0.id == id }) ?? 0
        var ids = minimizedIDs
        ids.insert(id)
        minimizedIDs = ids
        guard focusedID == id else { return }
        if let next = nearestVisible(to: index, excluding: id) {
            focus(next.id)
        } else {
            focusedID = nil
        }
    }

    func expand(_ id: UUID) {
        guard minimizedIDs.contains(id), let session = sessions.first(where: { $0.id == id }) else { return }
        session.terminalView.suppressTinyFrames = false
        session.terminalView.isHidden = false
        session.terminalView.needsDisplay = true
        var ids = minimizedIDs
        ids.remove(id)
        minimizedIDs = ids
        focus(id)
    }

    /// Focus a session, expanding it when it is sitting in the minimized section.
    func activate(_ id: UUID) {
        if minimizedIDs.contains(id) {
            expand(id)
        } else {
            focus(id)
        }
    }

    func focusIndex(_ index: Int) {
        let visible = visibleSessions
        guard visible.indices.contains(index) else { return }
        focus(visible[index].id)
    }

    func beginRenaming(_ id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        focus(id)
        renamingSessionID = id
    }

    func beginRenamingFocused() {
        guard let focusedID else { return }
        beginRenaming(focusedID)
    }

    /// Drop a window onto a visible slot. Minimized sessions stay parked in place.
    func moveVisible(_ id: UUID, toSlot slot: Int) {
        let ids = sessions.map(\.id)
        let next = reorderOccupyingSlot(
            all: ids,
            hidden: minimizedIDs,
            moving: id,
            toSlot: slot
        )
        guard next != ids else { return }
        let byID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
        sessions = next.compactMap { byID[$0] }
    }

    /// Snap every visible tile back onto the predetermined equal grid.
    /// Reorders nothing; bumps `layoutEpoch` so the canvas animates into place.
    func equalizeLayout() {
        layoutEpoch += 1
    }

    func cycleTheme(_ id: UUID) {
        guard let session = sessions.first(where: { $0.id == id }) else { return }
        session.theme.cycle()
    }

    func toggleFocusedTheme() {
        guard let focusedID else { return }
        cycleTheme(focusedID)
    }

    func close(_ id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        let wasFocused = focusedID == id
        var ids = minimizedIDs
        ids.remove(id)
        minimizedIDs = ids
        let next = wasFocused ? nearestVisible(to: index, excluding: id) : nil
        sessions[index].close()
        sessions.remove(at: index)
        if renamingSessionID == id {
            renamingSessionID = nil
        }
        if wasFocused {
            if let next {
                focus(next.id)
            } else {
                focusedID = nil
            }
        }
    }

    func closeFocused() {
        guard let focusedID else { return }
        close(focusedID)
    }

    func launchConfiguration() -> ShellLaunch {
        let defaults = UserDefaults.standard
        let shell = ShellEnvironment.resolvedShell(
            override: defaults.string(forKey: SettingsKey.shellPath) ?? ""
        )
        let reportAsITerm = defaults.object(forKey: SettingsKey.reportAsITerm) as? Bool ?? true
        return ShellLaunch(
            executable: shell,
            directory: directoryForNewTerminal(),
            environment: ShellEnvironment.variables(reportAsITerm: reportAsITerm)
        )
    }

    func directoryForNewTerminal() -> String {
        let defaults = UserDefaults.standard
        let useFocused = defaults.object(forKey: SettingsKey.useFocusedDirectory) as? Bool ?? true
        if useFocused, let directory = focusedSession?.directory, directoryExists(directory) {
            return directory
        }
        let custom = (defaults.string(forKey: SettingsKey.customDirectory) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty {
            let expanded = (custom as NSString).expandingTildeInPath
            if directoryExists(expanded) { return expanded }
        }
        return ShellEnvironment.homeDirectory()
    }

    func restart(_ session: TerminalSession) {
        let fontSize = CGFloat(UserDefaults.standard.double(forKey: SettingsKey.fontSize).nonZero(or: 13))
        var launch = launchConfiguration()
        if let directory = session.directory, directoryExists(directory) {
            launch.directory = directory
        }
        session.restart(fontSize: fontSize, launch: launch)
    }

    private func makeSession() -> TerminalSession {
        let ordinal = nextOrdinal
        nextOrdinal += 1
        let stored = UserDefaults.standard.double(forKey: SettingsKey.fontSize)
        let session = TerminalSession(ordinal: ordinal, fontSize: CGFloat(stored.nonZero(or: 13)))
        session.theme = ShellEnvironment.defaultTheme()
        session.prepare(launchConfiguration())
        return session
    }

    private func nearestVisible(to index: Int, excluding id: UUID) -> TerminalSession? {
        let visible = sessions.enumerated().filter { offset, session in
            offset != index && session.id != id && !minimizedIDs.contains(session.id)
        }
        guard !visible.isEmpty else { return nil }
        if let next = visible.first(where: { $0.offset > index }) {
            return next.element
        }
        return visible.last?.element
    }

    private func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

private extension Double {
    func nonZero(or fallback: Double) -> Double {
        self > 0 ? self : fallback
    }
}
