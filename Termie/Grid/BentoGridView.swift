import AppKit
import SwiftUI
import TermieCore

struct BentoGridView: View {
    @Environment(SessionStore.self) private var store
    @State private var frames: [UnitRect] = []
    @State private var userSized = false
    @State private var drag: DividerDrag?

    var body: some View {
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
            GeometryReader { proxy in
                let display = resolvedFrames()
                let dividers = tileDividers(in: display)
                ZStack(alignment: .topLeading) {
                    ForEach(Array(store.sessions.enumerated()), id: \.element.id) { index, session in
                        let rect = tileRect(display[index], in: proxy.size)
                        SessionTile(session: session)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                    ForEach(Array(dividers.enumerated()), id: \.offset) { index, divider in
                        DividerHandle(
                            divider: divider,
                            size: proxy.size,
                            isDragging: drag?.index == index,
                            onDrag: { translation in
                                resize(divider, index: index, translation: translation, in: proxy.size)
                            },
                            onDragEnd: {
                                drag = nil
                            }
                        )
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .padding(6)
            .onChange(of: sessionIdentity) { _, _ in
                userSized = false
                frames = []
                drag = nil
            }
        }
    }

    private var sessionIdentity: [UUID] {
        store.sessions.map(\.id)
    }

    /// Tiles are inset so the seam between them is an empty gutter the divider can sit in.
    private func tileRect(_ unit: UnitRect, in size: CGSize) -> CGRect {
        CGRect(
            x: unit.x * size.width + 4,
            y: unit.y * size.height + 4,
            width: max(0, unit.width * size.width - 8),
            height: max(0, unit.height * size.height - 8)
        )
    }

    private func resolvedFrames() -> [UnitRect] {
        if userSized, frames.count == store.sessions.count {
            return frames
        }
        return bentoFrames(count: store.sessions.count)
    }

    private func resize(_ divider: TileDivider, index: Int, translation: CGSize, in size: CGSize) {
        let base: [UnitRect]
        let origin: TileDivider
        if let drag, drag.index == index {
            base = drag.frames
            origin = drag.divider
        } else {
            base = resolvedFrames()
            origin = divider
            drag = DividerDrag(index: index, frames: base, divider: origin)
        }
        let delta = origin.axis == .vertical
            ? translation.width / size.width
            : translation.height / size.height
        let minimum = minimumSpan(along: origin.axis, in: size)
        frames = resizeTiles(base, divider: origin, to: origin.position + delta, minimum: minimum)
        userSized = true
    }

    private func minimumSpan(along axis: TileDivider.Axis, in size: CGSize) -> Double {
        let length = axis == .vertical ? size.width : size.height
        guard length > 1 else { return 0.12 }
        return min(0.4, max(0.12, 160 / length))
    }
}

private struct DividerDrag {
    var index: Int
    var frames: [UnitRect]
    var divider: TileDivider
}

private struct DividerHandle: View {
    var divider: TileDivider
    var size: CGSize
    var isDragging: Bool
    var onDrag: (CGSize) -> Void
    var onDragEnd: () -> Void

    @State private var hovering = false
    @State private var cursorPushed = false

    private let hitThickness: CGFloat = 14

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.secondary.opacity(hovering || isDragging ? 0.55 : 0.28))
                .frame(width: gripWidth, height: gripHeight)
        }
        .frame(width: hitWidth, height: hitHeight)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onChange(of: hovering || isDragging) { _, active in
            setCursor(active)
        }
        .onDisappear {
            setCursor(false)
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { onDrag($0.translation) }
                .onEnded { _ in onDragEnd() }
        )
        .position(x: centerX, y: centerY)
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

    private var cursor: NSCursor {
        divider.axis == .vertical ? .resizeLeftRight : .resizeUpDown
    }

    private var hitWidth: CGFloat {
        divider.axis == .vertical ? hitThickness : max(hitThickness, spanLength)
    }

    private var hitHeight: CGFloat {
        divider.axis == .vertical ? max(hitThickness, spanLength) : hitThickness
    }

    private var gripWidth: CGFloat {
        divider.axis == .vertical ? 3 : min(36, spanLength * 0.18)
    }

    private var gripHeight: CGFloat {
        divider.axis == .vertical ? min(36, spanLength * 0.18) : 3
    }

    private var spanLength: CGFloat {
        max(0, (divider.end - divider.start) * (divider.axis == .vertical ? size.height : size.width))
    }

    private var centerX: CGFloat {
        switch divider.axis {
        case .vertical:
            return divider.position * size.width
        case .horizontal:
            return (divider.start + divider.end) / 2 * size.width
        }
    }

    private var centerY: CGFloat {
        switch divider.axis {
        case .vertical:
            return (divider.start + divider.end) / 2 * size.height
        case .horizontal:
            return divider.position * size.height
        }
    }
}
