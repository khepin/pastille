import SwiftUI

@Observable
@MainActor
final class AppState {
    var isPanelVisible = false
    var selectedIndex = 0
    var searchText = ""
    var isSearchMode = false
    var historyItems: [HistoryItem] = []

    var filteredItems: [HistoryItem] {
        if searchText.isEmpty {
            return historyItems
        }
        let results = historyItems.filter { item in
            item.plainTextPreview?.localizedCaseInsensitiveContains(searchText) == true
        }
        print("[Pastille Filter] searchText=\"\(searchText)\" total=\(historyItems.count) matched=\(results.count)")
        return results
    }

    func resetSelection() {
        selectedIndex = 0
    }

    func moveSelection(by offset: Int) {
        let count = filteredItems.count
        guard count > 0 else {
            print("[Pastille Nav] moveSelection: no items")
            return
        }
        let old = selectedIndex
        selectedIndex = max(0, min(count - 1, selectedIndex + offset))
        print("[Pastille Nav] moveSelection(\(offset)): \(old) → \(selectedIndex) (filteredCount=\(count), isSearchMode=\(isSearchMode))")
    }

    var selectedItem: HistoryItem? {
        let items = filteredItems
        guard selectedIndex >= 0, selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }
}
