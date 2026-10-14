import AppKit
import SwiftUI
import TermieCore

struct CanvasGridView: View {
    @Environment(SessionStore.self) private var store
    @State private var frames: [UnitRect] = []
    @State private var userSized = false
    @State private var cornerDrag: CornerDrag?
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
                let display = resolvedFrames()
                ZStack(alignment: .topLeading) {
                    ForEach(Array(store.visibleSessions.enumerated()), id: \.element.id) { index, session in
                        let unit = display[index]
                        let rect = tileRect(unit, in: proxy.size)
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
                        }

                        ForEach(TileCorner.allCases, id: \.self) { corner in
                            CornerHandle(
                                corner: corner,
                                anchor: cornerPoint(unit, corner: corner, in: proxy.size),
                                isDragging: cornerDrag?.tileIndex == index && cornerDrag?.corner == corner,
                                onDrag: { location in
                                    resizeCorner(
                                        of: index,
                                        corner: corner,
                                        location: location,
                                        in: proxy.size
                                    )
                                },
                                onDragEnd: {
                                    cornerDrag = nil
                                }
                            )
                        }
                    }
                }
                .coordinateSpace(name: "canvas")
                .frame(width: proxy.size.width, height: proxy.size.height)
                .animation(.snappy(duration: 0.22), value: store.layoutEpoch)
                .animation(.snappy(duration: 0.22), value: sessionIdentity)
            }
            .padding(6)
            .onChange(of: sessionIdentity) { _, _ in
                // New set or order: fall back to the equal canvas until the user resizes again.
                userSized = false
                frames = []
                cornerDrag = nil
            }
            .onChange(of: store.layoutEpoch) { _, _ in
                userSized = false
                frames = []
                cornerDrag = nil
            }
        }
    }

    private var sessionIdentity: [UUID] {
        store.visibleSessions.map(\.id)
    }

    /// Tiles are inset so adjacent shells keep a gutter the corner handles can sit in.
    private func tileRect(_ unit: UnitRect, in size: CGSize) -> CGRect {
        CGRect(
            x: unit.x * size.width + 4,
            y: unit.y * size.height + 4,
            width: max(0, unit.width * size.width - 8),
            height: max(0, unit.height * size.height - 8)
        )
    }

    private func cornerPoint(_ unit: UnitRect, corner: TileCorner, in size: CGSize) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: unit.minX * size.width, y: unit.minY * size.height)
        case .topRight:
            return CGPoint(x: unit.maxX * size.width, y: unit.minY * size.height)
        case .bottomLeft:
            return CGPoint(x: unit.minX * size.width, y: unit.maxY * size.height)
        case .bottomRight:
            return CGPoint(x: unit.maxX * size.width, y: unit.maxY * size.height)
        }
    }

    private func resolvedFrames() -> [UnitRect] {
        if userSized, frames.count == store.visibleSessions.count {
            return frames
        }
        return equalGridFrames(count: store.visibleSessions.count)
    }

    private func resizeCorner(
        of index: Int,
        corner: TileCorner,
        location: CGPoint,
        in size: CGSize
    ) {
        let base: [UnitRect]
        if let cornerDrag,
           cornerDrag.tileIndex == index,
           cornerDrag.corner == corner {
            base = cornerDrag.frames
        } else {
            base = resolvedFrames()
            cornerDrag = CornerDrag(tileIndex: index, corner: corner, frames: base)
        }
        let unitX = min(max(location.x / max(size.width, 1), 0), 1)
        let unitY = min(max(location.y / max(size.height, 1), 0), 1)
        let minimum = min(
            minimumSpan(along: .vertical, in: size),
            minimumSpan(along: .horizontal, in: size)
        )
        frames = resizeTileCorner(
            base,
            at: index,
            corner: corner,
            toX: unitX,
            toY: unitY,
            minimum: minimum
        )
        userSized = true
    }

    private func minimumSpan(along axis: TileDivider.Axis, in size: CGSize) -> Double {
        let length = axis == .vertical ? size.width : size.height
        guard length > 1 else { return 0.12 }
        return min(0.4, max(0.12, 160 / length))
    }
}

private struct CornerDrag {
    var tileIndex: Int
    var corner: TileCorner
    var frames: [UnitRect]
}

private struct CornerHandle: View {
    var corner: TileCorner
    var anchor: CGPoint
    var isDragging: Bool
    var onDrag: (CGPoint) -> Void
    var onDragEnd: () -> Void

    @State private var hovering = false
    @State private var cursorPushed = false

    private let hitSize: CGFloat = 14
    private let knobSize: CGFloat = 8

    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(hovering || isDragging ? 0.85 : 0.45))
            .frame(width: knobSize, height: knobSize)
            .frame(width: hitSize, height: hitSize)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .onChange(of: hovering || isDragging) { _, active in
                setCursor(active)
            }
            .onDisappear {
                setCursor(false)
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .named("canvas"))
                    .onChanged { onDrag($0.location) }
                    .onEnded { _ in onDragEnd() }
            )
            .position(x: anchor.x, y: anchor.y)
            .help("Drag corner to resize")
    }

    private func setCursor(_ active: Bool) {
        if active, !cursorPushed {
            NSCursor.crosshair.push()
            cursorPushed = true
        } else if !active, cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
    }
}
