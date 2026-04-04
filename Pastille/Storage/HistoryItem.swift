import Foundation
import SwiftData

@Model
final class HistoryItem {
    var timestamp: Date = Date()
    var bundleIdentifier: String?
    var appName: String?
    var isPinned: Bool = false
    var plainTextPreview: String?

    @Relationship(deleteRule: .cascade, inverse: \HistoryItemContent.item)
    var contents: [HistoryItemContent] = []

    init(
        timestamp: Date = Date(),
        bundleIdentifier: String? = nil,
        appName: String? = nil,
        plainTextPreview: String? = nil
    ) {
        self.timestamp = timestamp
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.plainTextPreview = plainTextPreview
    }
}
