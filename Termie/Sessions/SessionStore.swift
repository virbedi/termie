import AppKit
import Observation
import UserNotifications

@MainActor
@Observable
final class SessionStore {
    private(set) var sessions: [TerminalSession] = []
    var focusedID: UUID?
    private var nextOrdinal = 1
    private var ticker: Timer?
    private var keyMonitor: Any?

    var focusedSession: TerminalSession? {
        sessions.first { $0.id == focusedID }
    }

    var attentionCount: Int {
        sessions.reduce(0) { count, session in
            if case .needsYou = session.presence { return count + 1 }
            return count
        }
    }

    var summary: String {
        let working = sessions.reduce(0) { count, session in
            if case .working = session.presence { return count + 1 }
            return count
        }
        let need = attentionCount
        switch (need, working) {
        case (0, 0):
            return sessions.isEmpty ? "No terminals" : "Quiet"
        case (0, _):
            return working == 1 ? "1 working" : "\(working) working"
        case (_, 0):
            return need == 1 ? "1 needs you" : "\(need) need you"
        default:
            return "\(need) need you · \(working) working"
        }
    }

    init() {
        let session = makeSession()
        sessions = [session]
        focus(session.id)
        ticker = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        if let ticker {
            RunLoop.main.add(ticker, forMode: .common)
        }
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
        focusedID = id
        for session in sessions {
            session.setFocused(session.id == id)
        }
        updateDockBadge()
    }

    func focusIndex(_ index: Int) {
        guard sessions.indices.contains(index) else { return }
        focus(sessions[index].id)
    }

    func close(_ id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].close()
        sessions.remove(at: index)
        if focusedID == id {
            if sessions.isEmpty {
                focusedID = nil
            } else {
                let next = sessions[min(index, sessions.count - 1)]
                focus(next.id)
            }
        }
        updateDockBadge()
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
        session.prepare(launchConfiguration())
        session.onNeedsYou = { [weak self, weak session] reason in
            guard let self, let session else { return }
            self.announce(session, reason: reason)
        }
        return session
    }

    private func tick() {
        let now = Date()
        for session in sessions {
            session.tick(now)
        }
        updateDockBadge()
    }

    private func announce(_ session: TerminalSession, reason: String) {
        updateDockBadge()
        if UserDefaults.standard.bool(forKey: SettingsKey.beepOnAttention) {
            NSSound.beep()
        }
        let looking = NSApp.isActive && session.id == focusedID
        guard !looking else { return }
        let title = session.displayName
        let identifier = session.id.uuidString
        Task {
            await Self.postNotification(title: title, body: reason, identifier: identifier)
        }
    }

    private static func postNotification(title: String, body: String, identifier: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
        case .denied:
            return
        default:
            break
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try? await center.add(request)
    }

    private func updateDockBadge() {
        let count = attentionCount
        NSApp.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
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
