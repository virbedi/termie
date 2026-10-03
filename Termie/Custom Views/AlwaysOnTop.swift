import SwiftUI

// MARK: - Always on Top

/// Set this view as a background on e.g. the main view.
struct AlwaysOnTop: View {

    static let settingsKey = "window.setting.isAlwaysOnTop"

    @AppStorage(Self.settingsKey) var isAlwaysOnTop: Bool = false

    @State var window: NSWindow?

    var body: some View {
        WindowReflection(window: $window)
            .onReceive(window.publisher) { window in
                MainWindowFocus.register(window)
                window.alwaysOnTop = isAlwaysOnTop
            }
            .onChange(of: isAlwaysOnTop) { _, isOnTop in
                window?.alwaysOnTop = isOnTop
            }
    }
}

// MARK: - Main window

/// The menu bar lives outside the main window, and `openWindow` on a `WindowGroup` creates another one.
@MainActor
enum MainWindowFocus {
    private static weak var window: NSWindow?

    static func register(_ window: NSWindow) {
        self.window = window
    }

    static func reveal(openWindow: OpenWindowAction) {
        if let window, NSApp.windows.contains(where: { $0 === window }) {
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Always on Top Command

struct AlwaysOnTopCommand: Commands {

    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            AlwaysOnTopCheckbox("Toggle Always on Top")
        }
    }
}

// MARK: - Always on Top Checkbox

struct AlwaysOnTopCheckbox: View {

    let title: LocalizedStringKey

    @AppStorage(AlwaysOnTop.settingsKey) var isAlwaysOnTop: Bool = false

    init(_ title: LocalizedStringKey = "Always on top") {
        self.title = title
    }

    var body: some View {
        Toggle(title, isOn: $isAlwaysOnTop)
            .toggleStyle(.checkbox)
    }
}

// MARK: - Preview

#Preview {
    AlwaysOnTopCheckbox()
}
