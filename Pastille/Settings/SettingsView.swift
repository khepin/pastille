import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar-style tab bar
            HStack(spacing: 2) {
                toolbarButton(title: "General", icon: "gear", tag: 0)
                toolbarButton(title: "Shortcuts", icon: "keyboard", tag: 1)
                toolbarButton(title: "Exclusions", icon: "eye.slash", tag: 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case 0: GeneralSettingsView()
                case 1: ShortcutSettingsView()
                case 2: ExclusionSettingsView()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 400)
    }

    private func toolbarButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(height: 24)
                Text(title)
                    .font(.system(size: 11))
            }
            .frame(width: 72, height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedTab == tag ? .primary : .secondary)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedTab == tag ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }
}
