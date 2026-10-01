import SwiftUI
import TermieCore

struct BentoGridView: View {
    @Environment(SessionStore.self) private var store

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
                let emphasis = emphasizedIndex
                let frames = bentoFrames(
                    count: store.sessions.count,
                    emphasis: emphasis,
                    wide: proxy.size.width >= proxy.size.height
                )
                ZStack(alignment: .topLeading) {
                    ForEach(Array(store.sessions.enumerated()), id: \.element.id) { index, session in
                        SessionTile(session: session)
                            .frame(
                                width: max(0, frames[index].width * proxy.size.width - 8),
                                height: max(0, frames[index].height * proxy.size.height - 8)
                            )
                            .offset(
                                x: frames[index].x * proxy.size.width + 4,
                                y: frames[index].y * proxy.size.height + 4
                            )
                    }
                }
            }
            .padding(6)
        }
    }

    private var emphasizedIndex: Int {
        if let index = store.sessions.firstIndex(where: {
            if case .needsYou = $0.presence { return true }
            return false
        }) {
            return index
        }
        if let focusedID = store.focusedID,
           let index = store.sessions.firstIndex(where: { $0.id == focusedID }) {
            return index
        }
        return 0
    }
}
