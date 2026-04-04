import SwiftUI

struct EmptyStateView: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: hasSearch ? "magnifyingglass" : "clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(hasSearch ? "No matching items" : "No clipboard history yet")
                .font(.system(size: 19))
                .foregroundStyle(.secondary)

            if !hasSearch {
                Text("Copy something to get started")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
