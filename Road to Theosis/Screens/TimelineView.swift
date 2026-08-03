import SwiftUI

struct TimelineView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var logEntries: [LogEntry]
    @AppStorage(AppPreferenceKey.isPrayerTimingEnabled.storageKey) private var isPrayerTimingEnabled = true
    @AppStorage(AppPreferenceKey.timelineRange.storageKey) private var timelineRangeRaw = TimelineRange.always.rawValue

    private var timelineRange: TimelineRange {
        TimelineRange(rawValue: timelineRangeRaw) ?? .always
    }

    private var timelineRangeBinding: Binding<TimelineRange> {
        Binding {
            timelineRange
        } set: { newValue in
            timelineRangeRaw = newValue.rawValue
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerCard

                    if filteredEntries.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedEntries, id: \.date) { group in
                            dayCard(for: group)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Timeline")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("Your log history")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(isPrayerTimingEnabled ? "Prayer sessions, resistance, losses, and notes appear here in time order." : "Prayers, resistance, losses, and notes appear here in time order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Timeline range", selection: timelineRangeBinding) {
                    ForEach(TimelineRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var emptyState: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No log entries yet")
                    .font(.headline.weight(.semibold))
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyStateMessage: String {
        if logEntries.isEmpty {
            return isPrayerTimingEnabled ? "Your resistance, losses, notes, and prayer time will appear here once you start logging." : "Your resistance, losses, notes, and prayers will appear here once you start logging."
        }

        return "No entries match the current \(timelineRange.title.lowercased()) timeline range."
    }

    private func dayCard(for group: (date: Date, entries: [LogEntry])) -> some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(Self.dayFormatter.string(from: group.date))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(group.entries.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }

                VStack(spacing: 0) {
                    ForEach(group.entries) { entry in
                        TimelineRow(entry: entry, showsPrayerTiming: isPrayerTimingEnabled)

                        if entry.id != group.entries.last?.id {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
            }
        }
    }

    private var groupedEntries: [(date: Date, entries: [LogEntry])] {
        let sortedEntries = filteredEntries.sorted { $0.occurredAt > $1.occurredAt }
        let grouped = Dictionary(grouping: sortedEntries) { Calendar.current.startOfDay(for: $0.occurredAt) }

        return grouped
            .map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private var filteredEntries: [LogEntry] {
        guard let cutoffDate = timelineRange.cutoffDate(from: Date(), calendar: .current) else {
            return logEntries
        }

        return logEntries.filter { $0.occurredAt >= cutoffDate }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}

enum TimelineRange: String, CaseIterable, Identifiable {
    case always
    case ninetyDays
    case thirtyDays
    case fourteenDays
    case sevenDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .always:
            return "Always"
        case .ninetyDays:
            return "90 days"
        case .thirtyDays:
            return "30 days"
        case .fourteenDays:
            return "14 days"
        case .sevenDays:
            return "7 days"
        }
    }

    func cutoffDate(from date: Date, calendar: Calendar) -> Date? {
        switch self {
        case .always:
            return nil
        case .ninetyDays:
            return calendar.date(byAdding: .day, value: -90, to: date)
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: date)
        case .fourteenDays:
            return calendar.date(byAdding: .day, value: -14, to: date)
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: date)
        }
    }
}

private struct TimelineRow: View {
    let entry: LogEntry
    let showsPrayerTiming: Bool

    private var timeText: String {
        Self.timeFormatter.string(from: entry.occurredAt)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.kind.tint.opacity(0.14))

                Image(systemName: entry.kind.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.kind.tint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.kind.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let sinTitle = entry.sinTitle {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(sinTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Text(entry.sectionTitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(entry.sectionTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(timeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let progressPercentage = entry.progressPercentage {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("Purity")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer(minLength: 8)

                            Text(SinFrequencyScale.label(for: progressPercentage))
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(entry.kind.tint)
                        }

                        ProgressView(value: Double(progressPercentage) / 100)
                            .tint(entry.kind.tint)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(entry.kind.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if !entry.note.isEmpty {
                  
                } else if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    if showsPrayerTiming && entry.prayerDurationSeconds > 0 {
                        Label("\(entry.prayerDurationText) prayer", systemImage: "hands.sparkles")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(entry.kind.tint)
                    }

                    if let progressPercentage = entry.progressPercentage {
                        Text("Purity set to \(SinFrequencyScale.label(for: progressPercentage))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(entry.kind.tint)
                    } else {
                        Label(entry.kind.title, systemImage: entry.kind.symbolName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        TimelineView(
            backgroundTheme: .constant(.blood),
            logEntries: .constant([
                LogEntry(
                    kind: .victory,
                    sectionTitle: "Sins Against God",
                    sinTitle: "Neglect of Prayer",
                    note: "Stayed focused and prayed before starting the day.",
                    prayerMinutes: 10,
                    occurredAt: Date()
                ),
                LogEntry(
                    kind: .loss,
                    sectionTitle: "Sins of the Tongue",
                    sinTitle: "Criticism",
                    note: "Need to slow down before speaking.",
                    prayerMinutes: 0,
                    occurredAt: Date().addingTimeInterval(-3600)
                ),
                LogEntry(
                    kind: .sliderProgressUpdate,
                    sectionTitle: "Sins Against Others",
                    sinTitle: "Strife / Argumentative",
                    note: "Adjusted after evening reflection.",
                    prayerMinutes: 0,
                    progressPercentage: 62,
                    occurredAt: Date().addingTimeInterval(-7200)
                )
            ])
        )
    }
}
