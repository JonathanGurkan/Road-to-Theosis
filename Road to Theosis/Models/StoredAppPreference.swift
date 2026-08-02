import Foundation
import SwiftData

@Model
final class StoredAppPreference {
    var key: String = ""
    var value: String = ""
    var updatedAt: Date = Date()

    init(key: String, value: String, updatedAt: Date = Date()) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }
}
