import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage(SettingsKey.shellPath) private var shellPath = ""
    @AppStorage(SettingsKey.fontSize) private var fontSize = 13.0
    @AppStorage(SettingsKey.optionAsMeta) private var optionAsMeta = true
    @AppStorage(SettingsKey.reportAsITerm) private var reportAsITerm = true
    @AppStorage(SettingsKey.beepOnAttention) private var beepOnAttention = false
    @AppStorage(SettingsKey.useFocusedDirectory) private var useFocusedDirectory = true
    @AppStorage(SettingsKey.customDirectory) private var customDirectory = ""

    var body: some View {
        Form {
            Section("Shell") {
                TextField("Shell", text: $shellPath, prompt: Text(ShellEnvironment.resolvedShell(override: "")))
                Text("Leave this empty to use your login shell. New terminals are login shells, so your PATH, aliases, and tools match Terminal, VS Code, and Cursor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("New terminals follow the focused folder", isOn: $useFocusedDirectory)
                if !useFocusedDirectory {
                    TextField("Starting folder", text: $customDirectory, prompt: Text("~"))
                }
            }

            Section("Terminal") {
                LabeledContent("Font size") {
                    Slider(value: $fontSize, in: 11...20, step: 1) {
                        Text("Font size")
                    } minimumValueLabel: {
                        Text("11")
                    } maximumValueLabel: {
                        Text("20")
                    }
                    .frame(width: 220)
                }
                Toggle("Option key sends Esc", isOn: $optionAsMeta)
                Text("Claude Code shortcuts such as Option-Shift-Enter need this, the same setting iTerm calls “Esc+”.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Attention") {
                Toggle("Use the iTerm channel Claude already talks to", isOn: $reportAsITerm)
                Text("Claude names iTerm tabs and notifies them when it needs you. New terminals advertise that channel so those titles and pings land here. Applies to terminals you open after changing this.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Beep when a terminal needs you", isOn: $beepOnAttention)
            }
        }
        .formStyle(.grouped)
        .padding(12)
    }
}
