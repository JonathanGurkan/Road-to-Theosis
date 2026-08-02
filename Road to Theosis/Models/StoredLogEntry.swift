import Foundation
import SwiftData

@Model
final class StoredLogEntry {
    var id: UUID = UUID()
    var kindRawValue: String = LogEntry.Kind.note.rawValue
    var sectionTitle: String = ""
    var sinTitle: String?
    var note: String = ""
    var prayerMinutes: Int = 0
    var prayerDurationSeconds: Int = 0
    var progressPercentage: Int?
    var occurredAt: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        kindRawValue: String,
        sectionTitle: String,
        sinTitle: String?,
        note: String,
        prayerMinutes: Int,
        prayerDurationSeconds: Int,
        progressPercentage: Int?,
        occurredAt: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kindRawValue = kindRawValue
        self.sectionTitle = sectionTitle
        self.sinTitle = sinTitle
        self.note = note
        self.prayerMinutes = prayerMinutes
        self.prayerDurationSeconds = prayerDurationSeconds
        self.progressPercentage = progressPercentage
        self.occurredAt = occurredAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(entry: LogEntry) {
        self.init(
            id: entry.id,
            kindRawValue: entry.kind.rawValue,
            sectionTitle: entry.sectionTitle,
            sinTitle: entry.sinTitle,
            note: entry.note,
            prayerMinutes: entry.prayerMinutes,
            prayerDurationSeconds: entry.prayerDurationSeconds,
            progressPercentage: entry.progressPercentage,
            occurredAt: entry.occurredAt
        )
    }

    var entry: LogEntry {
        LogEntry(
            id: id,
            kind: LogEntry.Kind(rawValue: kindRawValue) ?? .note,
            sectionTitle: sectionTitle,
            sinTitle: sinTitle,
            note: note,
            prayerMinutes: prayerMinutes,
            prayerDurationSeconds: prayerDurationSeconds,
            progressPercentage: progressPercentage,
            occurredAt: occurredAt
        )
    }
}
