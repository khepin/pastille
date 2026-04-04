import Foundation
import SwiftData
import AppKit

@MainActor
final class StorageManager {
    let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("Pastille", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        let storeURL = appSupport.appendingPathComponent("Storage.sqlite")
        let config = ModelConfiguration(url: storeURL)

        do {
            modelContainer = try ModelContainer(
                for: HistoryItem.self, HistoryItemContent.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        modelContext = modelContainer.mainContext
    }

    func insert(bundleId: String?, appName: String?, contents: [(type: String, data: Data)]) {
        // Duplicate detection: skip if top item has identical plain text
        let plainText = contents
            .first(where: { $0.type == NSPasteboard.PasteboardType.string.rawValue })
            .flatMap { String(data: $0.data, encoding: .utf8) }

        print("[Pastille Storage] Inserting item: \"\(plainText?.prefix(80) ?? "nil")\" from \(appName ?? "unknown")")

        if let plainText, let topItem = fetchFirst() {
            if topItem.plainTextPreview == plainText {
                print("[Pastille Storage] Duplicate detected, updating timestamp")
                topItem.timestamp = Date()
                try? modelContext.save()
                return
            }
        }

        let item = HistoryItem(
            bundleIdentifier: bundleId,
            appName: appName,
            plainTextPreview: plainText.map { String($0.prefix(500)) }
        )

        for content in contents {
            let itemContent = HistoryItemContent(type: content.type, value: content.data)
            item.contents.append(itemContent)
        }

        modelContext.insert(item)
        do {
            try modelContext.save()
            print("[Pastille Storage] Saved successfully. Total items: \(fetchAll().count)")
        } catch {
            print("[Pastille Storage] SAVE FAILED: \(error)")
        }
    }

    func fetchAll() -> [HistoryItem] {
        let descriptor = FetchDescriptor<HistoryItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchFirst() -> HistoryItem? {
        var descriptor = FetchDescriptor<HistoryItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func deleteItem(_ item: HistoryItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    func deleteAll() {
        let items = fetchAll()
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    func pruneIfNeeded(maxCount: Int) {
        let allItems = fetchAll()
        guard allItems.count > maxCount else { return }

        let itemsToRemove = allItems
            .filter { !$0.isPinned }
            .dropFirst(maxCount)

        for item in itemsToRemove {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
