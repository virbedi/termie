import Foundation

enum SettingsKey {
    static let shellPath = "settings.shell.path"
    static let fontSize = "settings.font.size"
    static let optionAsMeta = "settings.optionAsMeta"
    static let reportAsITerm = "settings.reportAsITerm"
    static let beepOnAttention = "settings.beepOnAttention"
    static let useFocusedDirectory = "settings.newTerminal.useFocusedDirectory"
    static let customDirectory = "settings.newTerminal.customDirectory"
}

enum ShellEnvironment {
    static func resolvedShell(override: String) -> String {
        let trimmed = override.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, FileManager.default.isExecutableFile(atPath: trimmed) {
            return trimmed
        }
        if let shell = ProcessInfo.processInfo.environment["SHELL"], !shell.isEmpty {
            return shell
        }
        return "/bin/zsh"
    }

    /// Environment for a login shell. `TERM` matches what VS Code and Cursor
    /// advertise. Reporting as iTerm is what makes Claude Code publish the same
    /// tab titles, progress reports, and "needs you" notifications it sends there.
    static func variables(reportAsITerm: Bool) -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["TERM_PROGRAM"] = reportAsITerm ? "iTerm.app" : "termie"
        env["TERM_PROGRAM_VERSION"] = reportAsITerm ? "3.5.14" : "1.0"
        env["TERMIE"] = "1"
        return env.map { "\($0.key)=\($0.value)" }
    }

    static func homeDirectory() -> String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }
}
