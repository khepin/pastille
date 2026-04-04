import SwiftUI

struct SearchBarView: View {
    @Bindable var appState: AppState
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 19))

            TextField("Search clipboard history\u{2026}", text: Binding(
                get: { appState.searchText },
                set: { newValue in
                    let wasEmpty = appState.searchText.isEmpty
                    appState.searchText = newValue
                    // Auto-enter search mode when user starts typing
                    if !newValue.isEmpty && wasEmpty {
                        appState.isSearchMode = true
                    }
                    appState.resetSelection()
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .focused($isFieldFocused)

            if !appState.searchText.isEmpty {
                Button {
                    appState.searchText = ""
                    appState.isSearchMode = false
                    appState.resetSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 17))
                }
                .buttonStyle(.plain)
            }

            // Mode indicator
            Text(appState.isSearchMode ? "SEARCH" : "NAV")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    appState.isSearchMode
                        ? Color.accentColor.opacity(0.2)
                        : Color.secondary.opacity(0.15)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .foregroundStyle(appState.isSearchMode ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            isFieldFocused = true
        }
        .onChange(of: appState.isSearchMode) { _, isSearch in
            isFieldFocused = isSearch
        }
    }
}
