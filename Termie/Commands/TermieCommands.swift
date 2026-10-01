import SwiftUI

struct TermieCommands: Commands {
    var store: SessionStore

    var body: some Commands {
        CommandMenu("Terminal") {
            Button("New Terminal") {
                store.addSession()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Close Terminal") {
                store.closeFocused()
            }
            .keyboardShortcut("w", modifiers: .command)

            Button("Restart Terminal") {
                if let session = store.focusedSession {
                    store.restart(session)
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Divider()

            Button("Focus Next") {
                focusOffset(1)
            }
            .keyboardShortcut("]", modifiers: .command)

            Button("Focus Previous") {
                focusOffset(-1)
            }
            .keyboardShortcut("[", modifiers: .command)

            Divider()

            let jumpSessions = Array(store.sessions.prefix(9))
            ForEach(Array(jumpSessions.enumerated()), id: \.element.id) { index, session in
                Button("Focus \(session.displayName)") {
                    store.focus(session.id)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
        }
    }

    private func focusOffset(_ delta: Int) {
        guard !store.sessions.isEmpty else { return }
        let current = store.sessions.firstIndex { $0.id == store.focusedID } ?? 0
        let count = store.sessions.count
        let next = (current + delta + count) % count
        store.focus(store.sessions[next].id)
    }
}
