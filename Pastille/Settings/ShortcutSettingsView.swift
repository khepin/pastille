import SwiftUI
import KeyboardShortcuts

struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Show clipboard panel:", name: .showPanel)
            } header: {
                Text("Keyboard Shortcuts")
            } footer: {
                Text("Press the shortcut to show or hide the clipboard history panel.")
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    shortcutRow("Enter", "Paste selected item")
                    shortcutRow("Shift + Enter", "Paste as plain text")
                    shortcutRow("\u{2190} \u{2192} or \u{2191} \u{2193}", "Navigate tiles")
                    shortcutRow("Tab", "Toggle search / navigation mode")
                    shortcutRow("Escape", "Dismiss panel")
                    shortcutRow("Type", "Start searching")
                }
            } header: {
                Text("Panel Shortcuts")
            }
        }
        .formStyle(.grouped)
    }

    private func shortcutRow(_ key: String, _ description: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}
