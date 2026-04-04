import Foundation
import SwiftData

@Model
final class HistoryItemContent {
    var type: String = ""
    var value: Data?

    var item: HistoryItem?

    init(type: String, value: Data?) {
        self.type = type
        self.value = value
    }
}
