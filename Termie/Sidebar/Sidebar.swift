import SwiftUI
import TermieCore

struct SessionSidebar: View {
    @Environment(SessionStore.self) private var store
    @State private var query = ""

    private var filtered: [TerminalSession] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return store.sessions }
        return store.sessions.filter {
            $0.displayName.localizedCaseInsensitiveContains(trimmed)
                || ($0.directory?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    var body: some View {
        @Bindable var store = store
        List(filtered, selection: $store.focusedID) { session in
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color(for: session.presence))
                        .frame(width: 8, height: 8)
                    Text(session.displayName)
                        .lineLimit(1)
                }
                if let directory = session.directory {
                    Text(shortDirectory(directory))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .tag(session.id)
            .contextMenu {
                Button("Rename") {
                    store.beginRenaming(session.id)
                }
                Button("Use Terminal Title") {
                    session.followTitle()
                }
                .disabled(session.followsTitle)
                Button("Close") {
                    store.close(session.id)
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $query, placement: .sidebar, prompt: "Filter sessions")
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        .safeAreaInset(edge: .bottom) {
            Button {
                store.addSession()
            } label: {
                Label("New Terminal", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(10)
        }
        .onChange(of: store.focusedID) { _, id in
            if let id { store.focus(id) }
        }
    }

    private func color(for presence: SessionPresence) -> Color {
        switch presence {
        case .idle: .secondary
        case .working: .green
        case .needsYou: .orange
        case .exited: .red
        }
    }

    private func shortDirectory(_ path: String) -> String {
        let home = ShellEnvironment.homeDirectory()
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
