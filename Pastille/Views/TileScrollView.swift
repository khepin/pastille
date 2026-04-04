import SwiftUI

struct TileScrollView: View {
    @Bindable var appState: AppState
    let onSelect: (HistoryItem) -> Void

    var body: some View {
        let items = appState.filteredItems

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.element.persistentModelID) { index, item in
                        ClipboardTileView(
                            item: item,
                            index: index,
                            appState: appState
                        )
                        .id(item.persistentModelID)
                        .onTapGesture {
                            onSelect(item)
                        }
                    }
                }
                .padding(.horizontal, 17)
                .padding(.vertical, 7)
            }
            .onChange(of: appState.selectedIndex) { _, newIndex in
                guard newIndex >= 0, newIndex < items.count else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(items[newIndex].persistentModelID, anchor: .center)
                }
            }
        }
    }
}
