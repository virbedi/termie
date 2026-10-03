import SwiftUI
import TermieCore

struct SessionSidebar: View {
    @Environment(SessionStore.self) private var store
    @State private var query = ""

    private var filteredVisible: [TerminalSession] {
        store.visibleSessions.filter { matches($0) }
    }

    private var filteredMinimized: [TerminalSession] {
        store.minimizedSessions.filter { matches($0) }
    }

    var body: some View {
        @Bindable var store = store
        List(selection: $store.focusedID) {
            if !filteredVisible.isEmpty {
                if filteredMinimized.isEmpty {
                    ForEach(filteredVisible) { session in
                        openRow(session)
                    }
                } else {
                    Section("Open") {
                        ForEach(filteredVisible) { session in
                            openRow(session)
                        }
                    }
                }
            }
            if !filteredMinimized.isEmpty {
                Section("Minimized") {
                    ForEach(filteredMinimized) { session in
                        MinimizedSessionRow(session: session)
                            .selectionDisabled(true)
                    }
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

    private func matches(_ session: TerminalSession) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return session.displayName.localizedCaseInsensitiveContains(trimmed)
            || (session.directory?.localizedCaseInsensitiveContains(trimmed) ?? false)
    }

    private func openRow(_ session: TerminalSession) -> some View {
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
            Button("Minimize") {
                store.minimize(session.id)
            }
            Button("Close") {
                store.close(session.id)
            }
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

private struct MinimizedSessionRow: View {
    @Environment(SessionStore.self) private var store
    var session: TerminalSession
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color(for: session.presence))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .lineLimit(1)
                if let directory = session.directory {
                    Text(shortDirectory(directory))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if hovering {
                Button {
                    store.expand(session.id)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .help("Expand")
                .accessibilityLabel("Expand")
                Button {
                    store.close(session.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Close")
                .accessibilityLabel("Close")
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Expand") {
                store.expand(session.id)
            }
            Button("Close") {
                store.close(session.id)
            }
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
