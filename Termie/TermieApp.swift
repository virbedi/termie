import SwiftUI

@main
struct TermieApp: App {
    @State private var store = SessionStore()

    var body: some Scene {
        MainScene(store: store)
    }
}
