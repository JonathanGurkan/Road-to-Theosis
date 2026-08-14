import SwiftUI

struct TimelineView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    @Binding var logEntries: [LogEntry]
    let onUpdateEntry: (LogEntry) -> Void
    let onDeleteEntry: (LogEntry) -> Void
    @State private var editingEntry: LogEntry?

    private var timelineRange: TimelineRange {
        preferences.timelineRange
    }

    private var filteredEntries: [LogEntry] {
        let calendar = Calendar.current
        guard let cutoffDate = timelineRange.cutoffDate(from: .now, calendar: calendar) else {
            return logEntries
        }

        return logEntries.filter { $0.occurredAt >= cutoffDate }
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
            EditLogEntryView(backgroundTheme: $backgroundTheme, entry: entry, onSave: onUpdateEntry)
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
                        TimelineRow(entry: entry, showsPrayerTiming: preferences.isPrayerTimingEnabled) {
                            editingEntry = entry
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                onDeleteEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if entry.id != group.entries.last?.id {
                            Divider()
                                .padding(.leading, 32)
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

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}

struct TimelineRow: View {
    let entry: LogEntry
    let showsPrayerTiming: Bool
    let onEdit: (() -> Void)?

    init(entry: LogEntry, showsPrayerTiming: Bool, onEdit: (() -> Void)? = nil) {
        self.entry = entry
        self.showsPrayerTiming = showsPrayerTiming
        self.onEdit = onEdit
    }

    private var timeText: String {
        Self.timeFormatter.string(from: entry.occurredAt)
    }

    private var subtitleText: String? {
        if entry.isPrayerEntry, !entry.prayerConnectedSinTitles.isEmpty {
            return nil
        }

        if let sinTitle = trimmedSubtitle(entry.sinTitle), !isRedundantSubtitle(sinTitle) {
            return sinTitle
        }

        guard let sectionTitle = trimmedSubtitle(entry.sectionTitle), !isRedundantSubtitle(sectionTitle) else {
            return nil
        }

        return sectionTitle
    }

    private var prayerConnectedSins: [ConnectedSinReference] {
        entry.prayerConnectedSins
    }

    private struct DetailChip: Identifiable, Hashable {
        let id = UUID()
        let text: String
        let tint: Color?
    }

    private var detailChips: [DetailChip] {
        var chips: [DetailChip] = []

        if subtitleText == nil, !entry.isPrayerEntry, let contextChip = contextChipText {
            chips.append(DetailChip(text: contextChip, tint: nil))
        }

        if showsPrayerTiming && entry.isPrayerEntry && entry.prayerDurationSeconds > 0 {
            chips.append(DetailChip(text: entry.prayerDurationText, tint: entry.kind.tint))
        }

        if let progressPercentage = entry.progressPercentage {
            chips.append(DetailChip(text: SinFrequencyScale.label(for: progressPercentage), tint: nil))
        }

        return chips
    }

    private var contextChipText: String? {
        if let subtitleText {
            return subtitleText
        }

        switch entry.kind {
        case .prayer:
            return "Prayer session"
        case .quickPrayer:
            return "Brief prayer"
        case .victory:
            return "Resistance log"
        case .loss:
            return "Loss log"
        case .progressUpdate, .sliderProgressUpdate:
            return "Purity update"
        case .note:
            return nil
        }
    }

    private var relatedSinIconName: String? {
        if entry.isPrayerEntry, let iconName = entry.prayerConnectedSins.first?.resolvedIconName {
            return iconName
        }

        guard let sinTitle = entry.sinTitle else { return nil }

        for section in SinCategory.sample {
            guard section.title == entry.sectionTitle else { continue }

            if let match = section.items.first(where: { $0.title == sinTitle }) {
                return match.icon
            }
        }

        return nil
    }

    private var rowSpacing: CGFloat {
        entry.kind == .note ? 1 : 6
    }

    private var headerSpacing: CGFloat {
        entry.kind == .note ? 6 : 8
    }

    private var noteTopPadding: CGFloat {
        entry.kind == .note ? 0 : 2
    }

    private var primaryBadgeIconName: String {
        entry.kind.symbolName
    }

    private var secondaryBadgeIconName: String? {
        relatedSinIconName
    }

    private var primaryBadgeSize: CGFloat {
        36
    }

    private var primaryBadgeIconFont: Font {
        .system(size: 18, weight: .semibold)
    }

    private var secondaryBadgeSize: CGFloat {
        20
    }

    private var badgeOverlapOffset: CGSize {
        relatedSinIconName == nil ? .zero : CGSize(width: 10, height: -10)
    }

    private var titleLineText: String {
        entry.kind.title
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(entry.kind.tint.opacity(0.16))
                    .frame(width: primaryBadgeSize, height: primaryBadgeSize)
                    .shadow(color: .black.opacity(0.10), radius: 1.5, x: 0, y: 1)

                Image(systemName: primaryBadgeIconName)
                    .font(primaryBadgeIconFont)
                    .foregroundStyle(entry.kind.tint)

                if let secondaryBadgeIconName {
                    Circle()
                        .fill(entry.kind.tint)
                        .frame(width: secondaryBadgeSize, height: secondaryBadgeSize)
                        .shadow(color: .black.opacity(0.12), radius: 1.2, x: 0, y: 1)
                        .offset(x: badgeOverlapOffset.width, y: badgeOverlapOffset.height)

                    Image(systemName: secondaryBadgeIconName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: secondaryBadgeSize, height: secondaryBadgeSize)
                        .offset(x: badgeOverlapOffset.width, y: badgeOverlapOffset.height)
                }
            }
            .frame(width: primaryBadgeSize + 14, height: primaryBadgeSize + 14)

            VStack(alignment: .leading, spacing: rowSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: headerSpacing) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titleLineText)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        Text(timeText)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)

                        if let onEdit {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.primary.opacity(0.06), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit log entry")
                        }
                    }
                }

                if entry.isPrayerEntry, !prayerConnectedSins.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(prayerConnectedSins, id: \.id) { reference in
                            Text(reference.displayTitle)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                } else if let subtitleText {
                    Text(subtitleText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if !detailChips.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(detailChips) { chip in
                            Text(chip.text)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(chip.tint ?? .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background((chip.tint ?? .primary).opacity(chip.tint == nil ? 0.08 : 0.16), in: Capsule())
                        }
                    }
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(entry.kind == .note ? 3 : nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, noteTopPadding)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private func trimmedSubtitle(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func isRedundantSubtitle(_ text: String?) -> Bool {
        guard let text else { return true }

        let normalizedText = text.lowercased()
        let normalizedKindTitle = entry.kind.title.lowercased()

        if normalizedText == normalizedKindTitle {
            return true
        }

        if normalizedKindTitle.contains("prayer"), normalizedText.contains("prayer") {
            return true
        }

        if normalizedKindTitle.contains("note"), normalizedText.contains("note") {
            return true
        }

        if normalizedKindTitle.contains("purity"), normalizedText.contains("purity") {
            return true
        }

        return false
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
