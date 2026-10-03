import SwiftUI

struct MainView: View {
    @Environment(SessionStore.self) private var store

    var body: some View {
        NavigationSplitView {
            SessionSidebar()
        } detail: {
            BentoGridView()
                .navigationTitle(store.focusedSession?.displayName ?? "Termie")
                .navigationSubtitle(store.summary)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            store.addSession()
                        } label: {
                            Label("New Terminal", systemImage: "plus")
                        }
                        .help("New Terminal")
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .background {
            MinimizedTerminalPark()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// Keeps minimized shells on a hidden view at their last tile size so the process stays alive.
private struct MinimizedTerminalPark: NSViewRepresentable {
    @Environment(SessionStore.self) private var store

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let sessions = store.minimizedSessions
        let live = Set(sessions.map { ObjectIdentifier($0.terminalView) })
        for subview in nsView.subviews where !live.contains(ObjectIdentifier(subview)) {
            subview.removeFromSuperview()
        }
        for session in sessions {
            let view = session.terminalView
            view.suppressTinyFrames = true
            if view.superview !== nsView {
                nsView.addSubview(view)
            }
            view.isHidden = true
            let size = session.parkedSize
            if abs(view.bounds.width - size.width) > 0.5 || abs(view.bounds.height - size.height) > 0.5 {
                view.setFrameSize(size)
            }
            session.startIfNeeded()
        }
    }
}
