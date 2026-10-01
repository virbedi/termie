import SwiftUI

struct MenuBarMenu: View {
    @Environment(SessionStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if store.sessions.isEmpty {
            Button("New Terminal") {
                store.addSession()
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            ForEach(store.sessions) { session in
                Button {
                    store.focus(session.id)
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Text(label(for: session))
                }
            }
        }

        Divider()

        Button("New Terminal") {
            store.addSession()
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        SettingsLink()

        Divider()

        Button("Quit Termie") {
            NSApp.terminate(nil)
        }
    }

    private func label(for session: TerminalSession) -> String {
        switch session.presence {
        case .needsYou(let reason):
            return "\(session.displayName) — \(reason)"
        case .working:
            return "\(session.displayName) — Working"
        case .exited:
            return "\(session.displayName) — Exited"
        case .idle:
            return session.displayName
        }
    }
}
