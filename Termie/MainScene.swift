import AppKit
import SwiftUI

struct MainScene: Scene {
    var store: SessionStore

    var body: some Scene {
        Window("Termie", id: "main") {
            MainView()
                .environment(store)
                .frame(minWidth: 880, minHeight: 560)
                .background(AlwaysOnTop())
                .modifier(AppAppearance())
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            AboutCommand()
            AlwaysOnTopCommand()
            TermieCommands(store: store)
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarMenu()
                .environment(store)
        } label: {
            Image(systemName: "terminal")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsWindow()
                .modifier(AppAppearance())
        }

        Window("About Termie", id: "about") {
            AboutView(
                icon: NSApp.applicationIconImage ?? NSImage(),
                name: Bundle.main.name,
                version: Bundle.main.version,
                build: Bundle.main.buildVersion,
                copyright: Bundle.main.copyright,
                developerName: "Your shells, side by side"
            )
            .frame(width: 500, height: 260)
        }
        .windowResizability(.contentSize)

        Window("Attributions", id: "attributions") {
            AttributionsView()
                .frame(minWidth: 500, minHeight: 300)
        }
        .windowResizability(.contentMinSize)
    }
}

