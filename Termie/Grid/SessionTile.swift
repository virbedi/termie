import AppKit
import SwiftUI
import TermieCore

struct SessionTile: View {
    @Environment(SessionStore.self) private var store
    var session: TerminalSession
    var isDropTarget = false
    var isDragging = false
    var onWindowDrag: (CGSize, CGPoint) -> Void
    var onWindowDrop: (CGPoint) -> Void

    @State private var editing = false
    @State private var draft = ""
    @State private var headerHovering = false
    @State private var headerCursorPushed = false
    @FocusState private var nameFocused: Bool

    private var isFocused: Bool { store.focusedID == session.id }

    var body: some View {
        VStack(spacing: 0) {
            header
            TerminalHost(session: session)
                .id(session.viewGeneration)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(tileFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(stroke, lineWidth: isFocused || isDropTarget || hasExited ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(isDragging ? 0.28 : 0.14), radius: isDragging ? 18 : 7, y: isDragging ? 8 : 2)
        .contextMenu {
            Button("Rename") {
                store.beginRenaming(session.id)
            }
            Button("Use Terminal Title") {
                session.followTitle()
            }
            .disabled(session.followsTitle)
            Button("Use \(session.theme.nextTitle) Color") {
                store.cycleTheme(session.id)
            }
            if case .exited = session.presence {
                Button("Restart") {
                    store.restart(session)
                }
            }
            Divider()
            Button("Minimize") {
                store.minimize(session.id)
            }
            Button("Close") {
                store.close(session.id)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            name
            Spacer(minLength: 4)
                .contentShape(Rectangle())
                .onTapGesture { store.focus(session.id) }
            Button {
                store.cycleTheme(session.id)
            } label: {
                Circle()
                    .fill(Color(session.theme.swatch))
                    .overlay {
                        Circle().strokeBorder(headerInk.opacity(0.35), lineWidth: 1)
                    }
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.borderless)
            .help("Use \(session.theme.nextTitle.lowercased())")
            if case .exited = session.presence {
                Button("Restart") {
                    store.restart(session)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            Button {
                store.minimize(session.id)
            } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Minimize terminal")
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
        .foregroundStyle(headerInk)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(headerFill)
        .contentShape(Rectangle())
        .onHover { hovering in
            headerHovering = hovering
            setHeaderCursor(hovering || isDragging)
        }
        .onChange(of: isDragging) { _, dragging in
            setHeaderCursor(dragging || headerHovering)
        }
        .onDisappear { setHeaderCursor(false) }
        .simultaneousGesture(windowDrag)
        .onChange(of: store.renamingSessionID) { _, id in
            guard id == session.id else { return }
            draft = session.displayName
            editing = true
            store.renamingSessionID = nil
        }
    }

    private var windowDrag: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("canvas"))
            .onChanged { value in
                guard !editing else { return }
                onWindowDrag(value.translation, value.location)
            }
            .onEnded { value in
                guard !editing else { return }
                onWindowDrop(value.location)
            }
    }

    private func setHeaderCursor(_ active: Bool) {
        let cursor = isDragging ? NSCursor.closedHand : NSCursor.openHand
        if active, !headerCursorPushed {
            cursor.push()
            headerCursorPushed = true
        } else if active, headerCursorPushed {
            NSCursor.pop()
            cursor.push()
        } else if !active, headerCursorPushed {
            NSCursor.pop()
            headerCursorPushed = false
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

    private var hasExited: Bool {
        if case .exited = session.presence { return true }
        return false
    }

    private var tileFill: Color {
        Color(nsColor: TerminalPalette.colors(for: session.theme).background)
    }

    private var headerFill: Color {
        session.theme.prefersLightInterface
            ? Color(red: 0.93, green: 0.93, blue: 0.92)
            : Color(session.theme.swatch).opacity(0.55)
    }

    private var headerInk: Color {
        session.theme.prefersLightInterface
            ? Color.black.opacity(0.72)
            : Color.white.opacity(0.88)
    }

    private var stroke: Color {
        if isDropTarget || isFocused {
            return Color.accentColor.opacity(isDropTarget ? 0.9 : 0.85)
        }
        if hasExited {
            return .red.opacity(0.8)
        }
        return Color.primary.opacity(0.12)
    }

    private func finishEditing() {
        guard editing else { return }
        session.commitName(draft)
        editing = false
    }
}
