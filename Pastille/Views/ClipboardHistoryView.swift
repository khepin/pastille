import SwiftUI

struct ClipboardHistoryView: View {
    @Bindable var appState: AppState
    let onPaste: (HistoryItem, Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                SearchBarView(appState: appState)
                    .frame(width: geo.size.width * 0.5)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 50)
            .padding(.vertical, 14)

            if appState.filteredItems.isEmpty {
                EmptyStateView(hasSearch: !appState.searchText.isEmpty)
            } else {
                TileScrollView(
                    appState: appState,
                    onSelect: { item in
                        let plainTextOnly = NSEvent.modifierFlags.contains(.shift)
                        onPaste(item, plainTextOnly)
                    }
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
