import AppKit
import SwiftUI
import TermieCore

struct CanvasGridView: View {
    @Environment(SessionStore.self) private var store
    @State private var frames: [UnitRect] = []
    @State private var userSized = false
    @State private var cornerDrag: CornerDrag?
    @State private var edgeDrag: EdgeDrag?
    @State private var windowDrag: WindowDrag?

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
                let dropSlot = dropSlotIndex(in: display, canvasSize: proxy.size)
                ZStack(alignment: .topLeading) {
                    ForEach(Array(store.visibleSessions.enumerated()), id: \.element.id) { index, session in
                        let unit = display[index]
                        let rect = tileRect(unit, in: proxy.size)
                        let dragging = windowDrag?.id == session.id
                        let resizing = edgeDrag?.tileIndex == index || cornerDrag?.tileIndex == index
                        let aboveCover = drawsAboveOverlappingWindows(display, index: index)
                        SessionTile(
                            session: session,
                            isDropTarget: dropSlot == index && windowDrag?.id != session.id,
                            isDragging: dragging,
                            onWindowDrag: { translation, location in
                                windowDrag = WindowDrag(id: session.id, translation: translation, cursor: location)
                                store.focus(session.id)
                            },
                            onWindowDrop: { location in
                                let slot = canvasDropSlot(
                                    frames: display,
                                    at: unitPoint(location, in: proxy.size),
                                    moving: index
                                )
                                withAnimation(.snappy(duration: 0.22)) {
                                    store.moveVisible(session.id, toSlot: slot)
                                    windowDrag = nil
                                }
                            }
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .offset(dragging ? windowDrag?.translation ?? .zero : .zero)
                        .zIndex(dragging || resizing ? 2 : aboveCover ? 4 : 0)

                        resizeHandles(index: index, unit: unit, in: proxy.size, raised: resizing || aboveCover)
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
                edgeDrag = nil
            }
            .onChange(of: store.layoutEpoch) { _, _ in
                userSized = false
                frames = []
                cornerDrag = nil
                edgeDrag = nil
            }
        }
    }

    private var sessionIdentity: [UUID] {
        store.visibleSessions.map(\.id)
    }

    /// Tiles are inset so adjacent windows keep a gutter their edges can be grabbed in.
    private func tileRect(_ unit: UnitRect, in size: CGSize) -> CGRect {
        CGRect(
            x: unit.x * size.width + 4,
            y: unit.y * size.height + 4,
            width: max(0, unit.width * size.width - 8),
            height: max(0, unit.height * size.height - 8)
        )
    }

    @ViewBuilder
    private func resizeHandles(index: Int, unit: UnitRect, in size: CGSize, raised: Bool) -> some View {
        ForEach(TileEdge.allCases, id: \.self) { edge in
            ResizeHandle(
                cursor: edgeCursor(edge),
                frame: edgeHitRect(unit, edge: edge, in: size),
                onDrag: { location in
                    resizeEdge(of: index, edge: edge, location: location, in: size)
                },
                onDragEnd: { edgeDrag = nil }
            )
            .zIndex(raised ? 3 : 1)
        }
        ForEach(TileCorner.allCases, id: \.self) { corner in
            ResizeHandle(
                cursor: cornerCursor(corner),
                frame: cornerHitRect(unit, corner: corner, in: size),
                onDrag: { location in
                    resizeCorner(of: index, corner: corner, location: location, in: size)
                },
                onDragEnd: { cornerDrag = nil }
            )
            .zIndex(raised ? 3 : 1)
        }
    }

    private func edgeHitRect(_ unit: UnitRect, edge: TileEdge, in size: CGSize) -> CGRect {
        let thickness: CGFloat = 8
        let rect = CGRect(
            x: unit.minX * size.width,
            y: unit.minY * size.height,
            width: unit.width * size.width,
            height: unit.height * size.height
        )
        switch edge {
        case .left:
            return CGRect(x: rect.minX - thickness / 2, y: rect.minY + 12, width: thickness, height: max(0, rect.height - 24))
        case .right:
            return CGRect(x: rect.maxX - thickness / 2, y: rect.minY + 12, width: thickness, height: max(0, rect.height - 24))
        case .top:
            return CGRect(x: rect.minX + 12, y: rect.minY - thickness / 2, width: max(0, rect.width - 24), height: thickness)
        case .bottom:
            return CGRect(x: rect.minX + 12, y: rect.maxY - thickness / 2, width: max(0, rect.width - 24), height: thickness)
        }
    }

    private func cornerHitRect(_ unit: UnitRect, corner: TileCorner, in size: CGSize) -> CGRect {
        let side: CGFloat = 14
        let point: CGPoint
        switch corner {
        case .topLeft:
            point = CGPoint(x: unit.minX * size.width, y: unit.minY * size.height)
        case .topRight:
            point = CGPoint(x: unit.maxX * size.width, y: unit.minY * size.height)
        case .bottomLeft:
            point = CGPoint(x: unit.minX * size.width, y: unit.maxY * size.height)
        case .bottomRight:
            point = CGPoint(x: unit.maxX * size.width, y: unit.maxY * size.height)
        }
        return CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
    }

    private func dropSlotIndex(in frames: [UnitRect], canvasSize: CGSize) -> Int? {
        guard let windowDrag else { return nil }
        guard let index = store.visibleSessions.firstIndex(where: { $0.id == windowDrag.id }) else { return nil }
        return canvasDropSlot(frames: frames, at: unitPoint(windowDrag.cursor, in: canvasSize), moving: index)
    }

    private func unitPoint(_ location: CGPoint, in size: CGSize) -> CanvasPoint {
        CanvasPoint(
            x: location.x / max(size.width, 1),
            y: location.y / max(size.height, 1)
        )
    }

    private func resolvedFrames() -> [UnitRect] {
        if userSized, frames.count == store.visibleSessions.count {
            return frames
        }
        return equalGridFrames(count: store.visibleSessions.count)
    }

    private func resizeEdge(of index: Int, edge: TileEdge, location: CGPoint, in size: CGSize) {
        let base: [UnitRect]
        if let edgeDrag, edgeDrag.tileIndex == index, edgeDrag.edge == edge {
            base = edgeDrag.frames
        } else {
            base = resolvedFrames()
            edgeDrag = EdgeDrag(tileIndex: index, edge: edge, frames: base)
        }
        let alongX = edge == .left || edge == .right
        let position = alongX
            ? min(max(location.x / max(size.width, 1), 0), 1)
            : min(max(location.y / max(size.height, 1), 0), 1)
        frames = resizeTileEdge(
            base,
            at: index,
            edge: edge,
            to: position,
            minimum: minimumSpan(along: alongX ? .vertical : .horizontal, in: size)
        )
        userSized = true
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

    private func edgeCursor(_ edge: TileEdge) -> NSCursor {
        switch edge {
        case .left, .right: .resizeLeftRight
        case .top, .bottom: .resizeUpDown
        }
    }

    private func cornerCursor(_ corner: TileCorner) -> NSCursor {
        switch corner {
        case .topLeft, .bottomRight: WindowCursors.downRight()
        case .topRight, .bottomLeft: WindowCursors.downLeft()
        }
    }
}

private struct WindowDrag {
    var id: UUID
    var translation: CGSize
    var cursor: CGPoint
}

private struct CornerDrag {
    var tileIndex: Int
    var corner: TileCorner
    var frames: [UnitRect]
}

private struct EdgeDrag {
    var tileIndex: Int
    var edge: TileEdge
    var frames: [UnitRect]
}

private enum WindowCursors {
    static func downRight() -> NSCursor {
        diagonalCursor("arrow.up.left.and.arrow.down.right")
    }

    static func downLeft() -> NSCursor {
        diagonalCursor("arrow.up.right.and.arrow.down.left")
    }

    private static func diagonalCursor(_ symbol: String) -> NSCursor {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage()
        let configured = image.withSymbolConfiguration(.init(pointSize: 14, weight: .semibold)) ?? image
        return NSCursor(image: configured, hotSpot: NSPoint(x: configured.size.width / 2, y: configured.size.height / 2))
    }
}

private struct ResizeHandle: View {
    var cursor: NSCursor
    var frame: CGRect
    var onDrag: (CGPoint) -> Void
    var onDragEnd: () -> Void

    @State private var hovering = false
    @State private var dragging = false
    @State private var cursorPushed = false

    var body: some View {
        Color.clear
            .frame(width: frame.width, height: frame.height)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .onChange(of: hovering || dragging) { _, active in
                setCursor(active)
            }
            .onDisappear {
                setCursor(false)
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        dragging = true
                        onDrag(value.location)
                    }
                    .onEnded { _ in
                        dragging = false
                        onDragEnd()
                    }
            )
            .position(x: frame.midX, y: frame.midY)
    }

    private func setCursor(_ active: Bool) {
        if active, !cursorPushed {
            cursor.push()
            cursorPushed = true
        } else if !active, cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
    }
}
