import SwiftUI

struct TimelineView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var logEntries: [LogEntry]
    let onUpdateEntry: (LogEntry) -> Void
    let onDeleteEntry: (LogEntry) -> Void
    @State private var editingEntry: LogEntry?
    @AppStorage(AppPreferenceKey.isPrayerTimingEnabled.storageKey) private var isPrayerTimingEnabled = true
    @AppStorage(AppPreferenceKey.timelineRange.storageKey) private var timelineRangeRaw = TimelineRange.always.rawValue

    private var timelineRange: TimelineRange {
        TimelineRange(rawValue: timelineRangeRaw) ?? .always
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
        .sheet(item: $editingEntry) { entry in
            EditLogEntryView(backgroundTheme: $backgroundTheme, entry: entry, onDelete: {
                onDeleteEntry(entry)
                editingEntry = nil
            }) { updatedEntry in
                onUpdateEntry(updatedEntry)
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

                Text(isPrayerTimingEnabled ? "Prayer sessions, resistance, losses, and notes appear here in time order." : "Prayers, resistance, losses, and notes appear here in time order.")
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
                        TimelineRow(entry: entry, showsPrayerTiming: isPrayerTimingEnabled) {
                            editingEntry = entry
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

struct TimelineRow: View {
    let entry: LogEntry
    let showsPrayerTiming: Bool
    var showsEditButton = true
    let onEdit: () -> Void

    private var categoryStyle: LogEntryCategoryStyle {
        LogEntryCategoryStyle.style(for: entry)
    }

    private var timeText: String {
        Self.timeFormatter.string(from: entry.occurredAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(entry.kind.tint.opacity(0.14))

                    Image(systemName: entry.kind.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(entry.kind.tint)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.kind.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(timeText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 8)

                        if showsEditButton {
                            Button(action: onEdit) {
                                Label("Edit", systemImage: "pencil")
                                    .labelStyle(.iconOnly)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.primary.opacity(0.06), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(activityDetailText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let progressPercentage = entry.progressPercentage {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Purity")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(SinFrequencyScale.label(for: progressPercentage))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(entry.kind.tint)
                    }

                    ProgressView(value: Double(progressPercentage) / 100)
                        .tint(entry.kind.tint)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TimelineMetadataPill(text: entry.sectionTitle, systemImage: categoryStyle.systemImage, tint: categoryStyle.tint)

                    if let sinTitle = entry.sinTitle {
                        TimelineMetadataPill(text: sinTitle, systemImage: "target", tint: entry.kind.tint)
                    }

                    if showsPrayerTiming && entry.prayerDurationSeconds > 0 {
                        TimelineMetadataPill(text: "\(entry.prayerDurationText) prayer", systemImage: "hands.sparkles", tint: entry.kind.tint)
                    }

                    if let progressPercentage = entry.progressPercentage {
                        TimelineMetadataPill(text: SinFrequencyScale.label(for: progressPercentage), systemImage: "slider.horizontal.below.rectangle", tint: entry.kind.tint)
                    }
                }
                .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(entry.kind.tint.opacity(0.8))
                .frame(width: 3)
        }
        .padding(.vertical, 4)
    }

    private var activityDetailText: String {
        entry.activityDetailText(showsPrayerTiming: showsPrayerTiming)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

extension LogEntry {
    func activityDetailText(showsPrayerTiming: Bool) -> String {
        if let progressPercentage {
            return "Purity adjusted to \(SinFrequencyScale.label(for: progressPercentage))."
        }

        if showsPrayerTiming && prayerDurationSeconds > 0 {
            return "Prayer time logged for \(prayerDurationText)."
        }

        switch kind {
        case .victory:
            return sinTitle.map { "Resistance recorded for \($0)." } ?? "Resistance recorded."
        case .loss:
            return sinTitle.map { "Loss recorded for \($0)." } ?? "Loss recorded."
        case .prayer, .quickPrayer:
            return "Prayer entry recorded."
        case .note:
            return "Reflection note recorded."
        case .progressUpdate, .sliderProgressUpdate:
            return "Progress entry recorded."
        }
    }
}

struct LogEntryCategoryStyle {
    let systemImage: String
    let tint: Color

    static func style(for entry: LogEntry) -> LogEntryCategoryStyle {
        if let sinTitle = entry.sinTitle,
           let category = SinCategory.sample.flatMap(\.items).first(where: { $0.title == sinTitle }) {
            return LogEntryCategoryStyle(systemImage: category.icon, tint: category.tint)
        }

        if let section = SinCategory.sample.first(where: { $0.title == entry.sectionTitle }),
           let firstItem = section.items.first {
            return LogEntryCategoryStyle(systemImage: firstItem.icon, tint: section.tint)
        }

        return LogEntryCategoryStyle(systemImage: entry.kind.symbolName, tint: entry.kind.tint)
    }
}

private struct TimelineMetadataPill: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.055), in: Capsule())
    }
}

struct EditLogEntryView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let entry: LogEntry
    let onDelete: () -> Void
    let onSave: (LogEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var occurredAt: Date
    @State private var prayerDurationSeconds: Int
    @State private var progressPercentage: Int
    @State private var isShowingDeleteConfirmation = false

    init(
        backgroundTheme: Binding<AppBackgroundTheme>,
        entry: LogEntry,
        onDelete: @escaping () -> Void,
        onSave: @escaping (LogEntry) -> Void
    ) {
        self._backgroundTheme = backgroundTheme
        self.entry = entry
        self.onDelete = onDelete
        self.onSave = onSave
        self._note = State(initialValue: entry.note)
        self._occurredAt = State(initialValue: entry.occurredAt)
        self._prayerDurationSeconds = State(initialValue: entry.prayerDurationSeconds)
        self._progressPercentage = State(initialValue: entry.progressPercentage ?? 0)
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canEditPrayerDuration: Bool {
        entry.kind == .prayer || entry.kind == .quickPrayer || entry.prayerDurationSeconds > 0
    }

    private var canEditProgress: Bool {
        entry.progressPercentage != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: backgroundTheme)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        detailsCard
                        noteCard
                        deleteCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("Delete this log?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete Log", role: .destructive) {
                onDelete()
                dismiss()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the log entry and recalculates any affected purity progress.")
        }
    }

    private var summaryCard: some View {
        AppSurfaceCard {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(entry.kind.tint.opacity(0.14))

                    Image(systemName: entry.kind.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(entry.kind.tint)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.kind.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(targetText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var detailsCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("When", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])

                if canEditPrayerDuration {
                    Stepper(value: $prayerDurationSeconds, in: 0...10_800, step: 60) {
                        HStack {
                            Label("Prayer time", systemImage: "hands.sparkles")
                            Spacer()
                            Text(LogEntry.formatPrayerDuration(seconds: prayerDurationSeconds))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if canEditProgress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Purity", systemImage: "slider.horizontal.below.rectangle")
                            Spacer()
                            Text(SinFrequencyScale.label(for: progressPercentage))
                                .foregroundStyle(entry.kind.tint)
                        }

                        Slider(value: progressBinding, in: 0...100, step: 1)
                            .tint(entry.kind.tint)
                    }
                }
            }
        }
    }

    private var noteCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Note")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                TextEditor(text: $note)
                    .frame(minHeight: 160)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    private var deleteCard: some View {
        AppSurfaceCard {
            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete Log Entry", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var targetText: String {
        if let sinTitle = entry.sinTitle {
            return "\(entry.sectionTitle) / \(sinTitle)"
        }

        return entry.sectionTitle
    }

    private var progressBinding: Binding<Double> {
        Binding {
            Double(progressPercentage)
        } set: { newValue in
            progressPercentage = Int(newValue.rounded())
        }
    }

    private func save() {
        let updatedPrayerDurationSeconds = canEditPrayerDuration ? prayerDurationSeconds : entry.prayerDurationSeconds
        let updatedPrayerMinutes = canEditPrayerDuration ? updatedPrayerDurationSeconds / 60 : entry.prayerMinutes
        let updatedEntry = LogEntry(
            id: entry.id,
            kind: entry.kind,
            sectionTitle: entry.sectionTitle,
            sinTitle: entry.sinTitle,
            note: trimmedNote,
            prayerMinutes: updatedPrayerMinutes,
            prayerDurationSeconds: updatedPrayerDurationSeconds,
            progressPercentage: canEditProgress ? progressPercentage : entry.progressPercentage,
            occurredAt: occurredAt
        )

        onSave(updatedEntry)
        dismiss()
    }
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
}
