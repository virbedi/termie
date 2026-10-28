import AppKit
import SwiftUI
import TermieCore

/// App chrome follows the global default, not the focused tile.
struct AppAppearance: ViewModifier {
    @AppStorage(SettingsKey.defaultTheme) private var defaultTheme = ShellTheme.dark.rawValue

    func body(content: Content) -> some View {
        let theme = ShellTheme(rawValue: defaultTheme) ?? .dark
        content
            .preferredColorScheme(theme.prefersLightInterface ? .light : .dark)
            .onAppear { apply(theme) }
            .onChange(of: defaultTheme) { _, raw in
                apply(ShellTheme(rawValue: raw) ?? .dark)
            }
    }

    private func apply(_ theme: ShellTheme) {
        NSApp.appearance = NSAppearance(named: theme.prefersLightInterface ? .aqua : .darkAqua)
    }
}

extension Color {
    init(_ color: ThemeColor) {
        self.init(red: color.red, green: color.green, blue: color.blue)
    }
}
