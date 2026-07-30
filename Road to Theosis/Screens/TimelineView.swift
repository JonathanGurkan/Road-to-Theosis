import SwiftUI

struct TimelineView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var logEntries: [LogEntry]
    @AppStorage("isPrayerTimingEnabled") private var isPrayerTimingEnabled = true

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerCard

                    if logEntries.isEmpty {
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

                Text(isPrayerTimingEnabled ? "Prayer sessions, victories, losses, and notes appear here in time order." : "Prayers, victories, losses, and notes appear here in time order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No log entries yet")
                    .font(.headline.weight(.semibold))
                Text(isPrayerTimingEnabled ? "Your victories, losses, notes, and prayer time will appear here once you start logging." : "Your victories, losses, notes, and prayers will appear here once you start logging.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
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
        let sortedEntries = logEntries.sorted { $0.occurredAt > $1.occurredAt }
        let grouped = Dictionary(grouping: sortedEntries) { Calendar.current.startOfDay(for: $0.occurredAt) }

        return grouped
            .map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
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

                if !entry.note.isEmpty {
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

                    Label(entry.kind.title, systemImage: entry.kind.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
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
