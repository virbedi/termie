import AppKit
import SwiftTerm
import SwiftUI
import TermieCore

struct TerminalHost: NSViewRepresentable {
    var session: TerminalSession

    @Environment(SessionStore.self) private var store
    @AppStorage(SettingsKey.fontSize) private var fontSize = 13.0
    @AppStorage(SettingsKey.optionAsMeta) private var optionAsMeta = true

    func makeNSView(context: Context) -> TermieTerminalView {
        let view = session.terminalView
        applyTheme(session.theme, to: view)
        return view
    }

    func updateNSView(_ nsView: TermieTerminalView, context: Context) {
        let size = CGFloat(fontSize)
        if abs(nsView.font.pointSize - size) > 0.1 {
            nsView.font = .monospacedSystemFont(ofSize: size, weight: .regular)
        }
        nsView.optionAsMetaKey = optionAsMeta
        applyTheme(session.theme, to: nsView)
        nsView.onFocus = { [weak session] in
            guard let session else { return }
            store.focus(session.id)
        }
        nsView.onUsableSize = { [weak session, weak nsView] in
            guard let session, let nsView else { return }
            session.startIfNeeded()
            if session.id == store.focusedID {
                claimFocusIfNeeded(nsView)
            }
        }
        nsView.suppressTinyFrames = false
        nsView.isHidden = false
        // Layout often applies the real frame after this update; onUsableSize covers that.
        if nsView.bounds.width > 2, nsView.bounds.height > 2 {
            session.startIfNeeded()
        }
        if session.id == store.focusedID {
            claimFocusIfNeeded(nsView)
        }
    }

    private func claimFocusIfNeeded(_ view: TermieTerminalView) {
        guard let window = view.window else { return }
        let responder = window.firstResponder
        if responder === view { return }
        if let textView = responder as? NSTextView,
           textView.isDescendant(of: view) || view.isDescendant(of: textView) {
            return
        }
        window.makeFirstResponder(view)
    }

    private func applyTheme(_ theme: ShellTheme, to view: TermieTerminalView) {
        guard view.appliedTheme != theme else { return }
        let colors = TerminalPalette.colors(for: theme)
        view.nativeForegroundColor = colors.foreground
        view.nativeBackgroundColor = colors.background
        view.caretColor = colors.caret
        view.selectedTextBackgroundColor = colors.selection
        view.installColors(colors.ansi)
        view.appliedTheme = theme
    }
}

enum TerminalPalette {
    struct Colors {
        var foreground: NSColor
        var background: NSColor
        var caret: NSColor
        var selection: NSColor
        var ansi: [SwiftTerm.Color]
    }

    static func colors(for theme: ShellTheme) -> Colors {
        switch theme {
        case .dark:
            return Colors(
                foreground: NSColor(calibratedWhite: 0.86, alpha: 1),
                background: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1),
                caret: NSColor(calibratedWhite: 0.92, alpha: 1),
                selection: NSColor(calibratedRed: 0.24, green: 0.40, blue: 0.66, alpha: 1),
                ansi: SwiftTerm.Color.terminalAppColors
            )
        case .light:
            return Colors(
                foreground: NSColor(calibratedWhite: 0.16, alpha: 1),
                background: NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.97, alpha: 1),
                caret: NSColor(calibratedWhite: 0.12, alpha: 1),
                selection: NSColor(calibratedRed: 0.72, green: 0.84, blue: 0.96, alpha: 1),
                ansi: lightAnsi
            )
        case .blue:
            return Colors(
                foreground: NSColor(calibratedRed: 0.82, green: 0.88, blue: 0.95, alpha: 1),
                background: NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.16, alpha: 1),
                caret: NSColor(calibratedRed: 0.90, green: 0.94, blue: 0.98, alpha: 1),
                selection: NSColor(calibratedRed: 0.14, green: 0.28, blue: 0.52, alpha: 1),
                ansi: SwiftTerm.Color.terminalAppColors
            )
        case .gray:
            return Colors(
                foreground: NSColor(calibratedWhite: 0.86, alpha: 1),
                background: NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.16, alpha: 1),
                caret: NSColor(calibratedWhite: 0.92, alpha: 1),
                selection: NSColor(calibratedRed: 0.28, green: 0.29, blue: 0.31, alpha: 1),
                ansi: SwiftTerm.Color.terminalAppColors
            )
        case .green:
            return Colors(
                foreground: NSColor(calibratedRed: 0.78, green: 0.90, blue: 0.80, alpha: 1),
                background: NSColor(calibratedRed: 0.03, green: 0.09, blue: 0.06, alpha: 1),
                caret: NSColor(calibratedRed: 0.86, green: 0.95, blue: 0.88, alpha: 1),
                selection: NSColor(calibratedRed: 0.10, green: 0.28, blue: 0.18, alpha: 1),
                ansi: SwiftTerm.Color.terminalAppColors
            )
        }
    }

    /// Terminal.app palette with black/white swapped so bright text stays readable on light ground.
    private static let lightAnsi: [SwiftTerm.Color] = [
        SwiftTerm.Color(red8: 0x1c, green8: 0x1c, blue8: 0x1c),
        SwiftTerm.Color(red8: 0xc2, green8: 0x36, blue8: 0x21),
        SwiftTerm.Color(red8: 0x25, green8: 0x8b, blue8: 0x24),
        SwiftTerm.Color(red8: 0x9a, green8: 0x7b, blue8: 0x0a),
        SwiftTerm.Color(red8: 0x49, green8: 0x2e, blue8: 0xc1),
        SwiftTerm.Color(red8: 0xb0, green8: 0x2e, blue8: 0xb0),
        SwiftTerm.Color(red8: 0x1f, green8: 0x7f, blue8: 0x8c),
        SwiftTerm.Color(red8: 0x96, green8: 0x96, blue8: 0x96),
        SwiftTerm.Color(red8: 0x5c, green8: 0x5c, blue8: 0x5c),
        SwiftTerm.Color(red8: 0xd4, green8: 0x2f, blue8: 0x1b),
        SwiftTerm.Color(red8: 0x1f, green8: 0x9a, blue8: 0x1c),
        SwiftTerm.Color(red8: 0xb0, green8: 0x8f, blue8: 0x10),
        SwiftTerm.Color(red8: 0x58, green8: 0x33, blue8: 0xe6),
        SwiftTerm.Color(red8: 0xc4, green8: 0x30, blue8: 0xc4),
        SwiftTerm.Color(red8: 0x14, green8: 0x90, blue8: 0x90),
        SwiftTerm.Color(red8: 0xe9, green8: 0xeb, blue8: 0xeb),
    ]
}
