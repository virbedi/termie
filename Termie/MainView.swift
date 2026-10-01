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
    }
}
