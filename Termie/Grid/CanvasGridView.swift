import SwiftUI
import TermieCore

struct CanvasGridView: View {
    @Environment(SessionStore.self) private var store
    @State private var draggingID: UUID?
    @State private var dropTargetID: UUID?

    var body: some View {
        if store.visibleSessions.isEmpty {
            if store.sessions.isEmpty {
                ContentUnavailableView {
                    Label("No terminals", systemImage: "terminal")
                } description: {
                    Text("Open a shell to start a session.")
                } actions: {
                    Button("New Terminal") {
                        store.addSession()
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            } else {
                ContentUnavailableView {
                    Label("Minimized", systemImage: "minus.rectangle")
                } description: {
                    Text("Expand a terminal from the sidebar to bring it back.")
                }
            }
        } else {
            GeometryReader { proxy in
                let frames = equalGridFrames(count: store.visibleSessions.count)
                ZStack(alignment: .topLeading) {
                    ForEach(Array(store.visibleSessions.enumerated()), id: \.element.id) { index, session in
                        let rect = tileRect(frames[index], in: proxy.size)
                        SessionTile(
                            session: session,
                            isDropTarget: dropTargetID == session.id,
                            draggingID: $draggingID
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .opacity(draggingID == session.id ? 0.35 : 1)
                        .dropDestination(for: String.self) { items, _ in
                            guard let raw = items.first,
                                  let id = UUID(uuidString: raw),
                                  id != session.id else {
                                draggingID = nil
                                dropTargetID = nil
                                return false
                            }
                            withAnimation(.snappy(duration: 0.22)) {
                                store.moveVisible(id, before: session.id)
                            }
                            draggingID = nil
                            dropTargetID = nil
                            return true
                        } isTargeted: { targeted in
                            dropTargetID = targeted ? session.id : nil
                            if !targeted, draggingID == session.id {
                                // Drop cancelled or completed elsewhere.
                            }
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .animation(.snappy(duration: 0.22), value: store.layoutEpoch)
                .animation(.snappy(duration: 0.22), value: sessionIdentity)
            }
            .padding(6)
        }
    }

    private var sessionIdentity: [UUID] {
        store.visibleSessions.map(\.id)
    }

    /// Tiles are inset so adjacent shells keep a gutter between them.
    private func tileRect(_ unit: UnitRect, in size: CGSize) -> CGRect {
        CGRect(
            x: unit.x * size.width + 4,
            y: unit.y * size.height + 4,
            width: max(0, unit.width * size.width - 8),
            height: max(0, unit.height * size.height - 8)
        )
    }
}
