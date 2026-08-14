import SwiftUI

struct TimelineView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    @Binding var logEntries: [LogEntry]
    let onUpdateEntry: (LogEntry) -> Void
    let onDeleteEntry: (LogEntry) -> Void
    @State private var editingEntry: LogEntry?
    @State private var selectedCheckInEntry: LogEntry?

    private var timelineRange: TimelineRange {
        preferences.timelineRange
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerCard

                    if groupedEntries.isEmpty {
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
        .sheet(item: $selectedCheckInEntry) { entry in
            if let record = entry.checkInRecord {
                CheckInTimelineDetailView(backgroundTheme: backgroundTheme, entry: entry, record: record)
            }
        }
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

                Text(preferences.isPrayerTimingEnabled ? "Prayer sessions, resistance, losses, and notes appear here in time order." : "Prayers, resistance, losses, and notes appear here in time order.")
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
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyStateMessage: String {
        if logEntries.isEmpty {
            return preferences.isPrayerTimingEnabled ? "Your resistance, losses, notes, and prayer time will appear here once you start logging." : "Your resistance, losses, notes, and prayers will appear here once you start logging."
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
                        TimelineRow(entry: entry, showsPrayerTiming: preferences.isPrayerTimingEnabled)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard entry.checkInRecord != nil else { return }
                                selectedCheckInEntry = entry
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

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
        let visibleEntries = logEntries
            .filter { timelineRange.contains($0.occurredAt) }
            .sorted { $0.occurredAt > $1.occurredAt }
        let grouped = Dictionary(grouping: visibleEntries) { Calendar.current.startOfDay(for: $0.occurredAt) }

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

private struct CheckInTimelineDetailView: View {
    let backgroundTheme: AppBackgroundTheme
    let entry: LogEntry
    let record: CheckInRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        AppSurfaceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Check-in detail")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text(Self.dateFormatter.string(from: record.completedAt))
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("\(record.responses.count) answers recalibrated \(record.allChanges.count) purity areas.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ForEach(record.responses) { response in
                            responseCard(response)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func responseCard(_ response: CheckInResponse) -> some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(response.questionShortTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Text(response.answerTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(backgroundTheme.glowColor)
                }

                Text(response.questionPrompt)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(response.changes) { change in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(change.sinTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(change.sectionTitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Text("\(SinFrequencyScale.percentage(for: change.targetProgress))%")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(backgroundTheme.glowColor)
                    }
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
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
                    } else if entry.checkInRecord != nil {
                        Label("View answers", systemImage: "chevron.right.circle")
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
            ]),
            onUpdateEntry: { _ in },
            onDeleteEntry: { _ in }
        )
    }
    .environment(AppPreferenceStore())
}
