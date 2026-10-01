import SwiftUI

struct SessionTile: View {
    @Environment(SessionStore.self) private var store
    var session: TerminalSession

    @State private var editing = false
    @State private var draft = ""
    @FocusState private var nameFocused: Bool

    private var isFocused: Bool { store.focusedID == session.id }

    var body: some View {
        VStack(spacing: 0) {
            header
            TerminalHost(session: session)
                .id(session.viewGeneration)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(stroke, lineWidth: isFocused || needsYou ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contextMenu {
            Button("Rename") {
                store.beginRenaming(session.id)
            }
            Button("Use Terminal Title") {
                session.followTitle()
            }
            .disabled(session.followsTitle)
            if case .exited = session.presence {
                Button("Restart") {
                    store.restart(session)
                }
            }
            Divider()
            Button("Close") {
                store.close(session.id)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            statusMark
                .contentShape(Rectangle())
                .onTapGesture { store.focus(session.id) }
            name
            Spacer(minLength: 4)
                .contentShape(Rectangle())
                .onTapGesture { store.focus(session.id) }
            if case .exited = session.presence {
                Button("Restart") {
                    store.restart(session)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            Button {
                store.close(session.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Close terminal")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
        .onChange(of: store.renamingSessionID) { _, id in
            guard id == session.id else { return }
            draft = session.displayName
            editing = true
            store.renamingSessionID = nil
        }
    }

    @ViewBuilder
    private var name: some View {
        if editing {
            TextField("Name", text: $draft)
                .textFieldStyle(.plain)
                .font(.callout.weight(.medium))
                .focused($nameFocused)
                .onSubmit { finishEditing() }
                .onChange(of: nameFocused) { _, focused in
                    if !focused { finishEditing() }
                }
                .onAppear { nameFocused = true }
        } else {
            HStack(spacing: 4) {
                Text(session.displayName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                if !session.followsTitle {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .onTapGesture(count: 2) {
                draft = session.displayName
                editing = true
            }
            .onTapGesture {
                store.focus(session.id)
            }
        }
    }

    private var statusMark: some View {
        HStack(spacing: 5) {
            Image(systemName: statusSymbol)
                .symbolRenderingMode(.palette)
                .foregroundStyle(statusColor, statusColor.opacity(0.35))
                .symbolEffect(.pulse, isActive: needsYou)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
        .help(statusText)
    }

    private var needsYou: Bool {
        if case .needsYou = session.presence { return true }
        return false
    }

    private var statusSymbol: String {
        switch session.presence {
        case .idle: "circle"
        case .working: "circle.fill"
        case .needsYou: "exclamationmark.circle.fill"
        case .exited: "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch session.presence {
        case .idle: .secondary
        case .working: .green
        case .needsYou: .orange
        case .exited: .red
        }
    }

    private var statusText: String {
        switch session.presence {
        case .idle: "Idle"
        case .working: "Working"
        case .needsYou(let reason): reason
        case .exited(let code): "Exited \(code)"
        }
    }

    private var stroke: Color {
        switch session.presence {
        case .needsYou: .orange
        case .exited: .red.opacity(0.8)
        case .working where isFocused: .accentColor
        default: isFocused ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.12)
        }
    }

    private func finishEditing() {
        guard editing else { return }
        session.commitName(draft)
        editing = false
    }
}
