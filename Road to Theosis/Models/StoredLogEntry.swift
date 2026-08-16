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
    var connectedSinsData: String = "[]"
    var progressPercentage: Int?
    var checkInRecordJSON: String?
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
        connectedSins: [ConnectedSinReference] = [],
        progressPercentage: Int?,
        checkInRecordJSON: String? = nil,
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
        self.connectedSinsData = StoredLogEntry.encodeConnectedSins(connectedSins)
        self.progressPercentage = progressPercentage
        self.checkInRecordJSON = checkInRecordJSON
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
            connectedSins: entry.connectedSins,
            progressPercentage: entry.progressPercentage,
            checkInRecordJSON: entry.checkInRecordJSON,
            occurredAt: entry.occurredAt
        )
    }

    var connectedSins: [ConnectedSinReference] {
        get { StoredLogEntry.decodeConnectedSins(from: connectedSinsData) }
        set { connectedSinsData = StoredLogEntry.encodeConnectedSins(newValue) }
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
            connectedSins: connectedSins,
            progressPercentage: progressPercentage,
            checkInRecordJSON: checkInRecordJSON,
            occurredAt: occurredAt
        )
    }

    private static func encodeConnectedSins(_ connectedSins: [ConnectedSinReference]) -> String {
        guard !connectedSins.isEmpty else { return "[]" }

        do {
            let data = try JSONEncoder().encode(connectedSins)
            return String(decoding: data, as: UTF8.self)
        } catch {
            return "[]"
        }
    }

    private static func decodeConnectedSins(from data: String) -> [ConnectedSinReference] {
        guard let jsonData = data.data(using: .utf8), !jsonData.isEmpty else { return [] }

        do {
            return try JSONDecoder().decode([ConnectedSinReference].self, from: jsonData)
        } catch {
            return []
        }
    }
}
