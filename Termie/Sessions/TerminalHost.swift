import SwiftUI

struct TerminalHost: NSViewRepresentable {
    var session: TerminalSession

    @Environment(SessionStore.self) private var store
    @AppStorage(SettingsKey.fontSize) private var fontSize = 13.0
    @AppStorage(SettingsKey.optionAsMeta) private var optionAsMeta = true

    func makeNSView(context: Context) -> TermieTerminalView {
        session.terminalView
    }

    func updateNSView(_ nsView: TermieTerminalView, context: Context) {
        let size = CGFloat(fontSize)
        if abs(nsView.font.pointSize - size) > 0.1 {
            nsView.font = .monospacedSystemFont(ofSize: size, weight: .regular)
        }
        nsView.optionAsMetaKey = optionAsMeta
        nsView.onFocus = { [weak session] in
            guard let session else { return }
            store.focus(session.id)
        }
        if nsView.bounds.width > 2, nsView.bounds.height > 2 {
            session.startIfNeeded()
        }
        if session.id == store.focusedID {
            claimFocusIfNeeded(nsView)
        }
    }

    private func claimFocusIfNeeded(_ view: TermieTerminalView) {
        guard let window = view.window else { return }
        let responder = window.firstResponder
        if responder === view { return }
        if responder is NSTextView { return }
        window.makeFirstResponder(view)
    }
}
