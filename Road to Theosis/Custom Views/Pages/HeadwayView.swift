import SwiftUI
import Playgrounds

struct HeadwayView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @State private var isShowingAddView = false
    @State private var isShowingQuickPrayer = false
    @State private var isShowingPrayerTimer = false
    @State private var selectedDefenseItem: SinCategory?
    @AppStorage("showRecentActivity") private var showRecentActivity = true
    @AppStorage("compactSinRows") private var compactSinRows = false
    @AppStorage("isPrayerTimingEnabled") private var isPrayerTimingEnabled = true
    @AppStorage("enableVerseInventory") private var enableVerseInventory = true
    @AppStorage("prayerTimerCountingMode") private var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue

    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        PrayerTimerCountingMode(rawValue: prayerTimerCountingModeRaw) ?? .foreground
    }

    private var greeting: String {
        Self.greeting(for: .now)
    }

    private static func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    private var progressSubtitle: String {
        Self.subtitleFormatter.string(from: Date())
    }

    private var quickActionSubtitle: String {
        guard isPrayerTimingEnabled else {
            return "Add a prayer, victory, loss, or note without focusing on time."
        }

        switch prayerTimerCountingMode {
        case .foreground:
            return "Start a quiet prayer session or add a victory, loss, or note."
        case .background:
            return "Start a prayer session that can keep counting in the background, or add a victory, loss, or note."
        }
    }

    private var recentEntries: [LogEntry] {
        Array(logEntries.sorted { $0.occurredAt > $1.occurredAt }.prefix(3))
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    headerCard
                    overviewCard
                    actionCard
                    sectionsHeader
                    LazyVStack(spacing: compactSinRows ? 10 : 12) {
                        ForEach(dashboard.sections.indices, id: \.self) { index in
                            SinSectionCardView(
                                section: $dashboard.sections[index],
                                isCompact: compactSinRows,
                                onShowVerses: { item in
                                    guard enableVerseInventory else { return }
                                    selectedDefenseItem = item
                                },
                                onVictory: { itemID in
                                    dashboard.markVictory(in: itemID)
                                },
                                onReset: { itemID in
                                    dashboard.resetItem(itemID)
                                }
                            )
                        }
                    }
                    if showRecentActivity {
                        recentActivityCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Today")
        .toolbar {
            Button {
                isShowingAddView.toggle()
            } label: {
                Label("Add Log", systemImage: "plus.circle.fill")
            }
        }
        .sheet(isPresented: $isShowingAddView) {
            AddLoggingView(backgroundTheme: $backgroundTheme) { entry in
                logEntries.insert(entry, at: 0)
                dashboard.record(entry)
            }
        }
        .sheet(isPresented: $isShowingQuickPrayer) {
            AddLoggingView(backgroundTheme: $backgroundTheme, onSave: { entry in
                logEntries.insert(entry, at: 0)
                dashboard.record(entry)
            }, initialMode: .quickPrayer)
        }
        .onChange(of: isPrayerTimingEnabled) { _, isEnabled in
            if !isEnabled {
                isShowingPrayerTimer = false
            }
        }
        .fullScreenCover(isPresented: $isShowingPrayerTimer) {
            PrayerTimerView(backgroundTheme: $backgroundTheme) { entry in
                logEntries.insert(entry, at: 0)
                dashboard.record(entry)
            }
        }
        .sheet(item: $selectedDefenseItem) { item in
            DefenseVersesSheetView(category: item)
        }
    }

    private var headerCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(progressSubtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(greeting)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Prayer, progress, and recent activity are gathered here in a cleaner, more native layout.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Label(latestActivitySummary, systemImage: latestActivityIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 8)

                    Text("Updated \(progressSubtitle)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(backgroundTheme.glowColor)
                }
            }
        }
    }

    private var overviewCard: some View {
        AppSurfaceCard(contentPadding: 16) {
            HStack(alignment: .center, spacing: 18) {
                progressRing

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Daily overview")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(Int(dashboard.totalProgress * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)
                    }

                    Text("Your current direction today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                        .padding(.bottom, 10)

                    VStack(spacing: 0) {
                        if isPrayerTimingEnabled {
                            StatCardView(
                                title: "Prayer minutes",
                                value: "\(dashboard.prayerMinutes)m",
                                icon: "hands.sparkles",
                                tint: backgroundTheme.glowColor
                            )

                            Divider()
                                .padding(.leading, 46)
                        }

                        StatCardView(
                            title: "Check-ins",
                            value: "\(dashboard.dailyCheckIns)",
                            icon: "checklist",
                            tint: backgroundTheme.glowColor
                        )

                        Divider()
                            .padding(.leading, 46)

                        StatCardView(
                            title: "Active streak",
                            value: "\(dashboard.activeStreak)d",
                            icon: "flame.fill",
                            tint: backgroundTheme.glowColor
                        )
                    }
                }
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(0.05, dashboard.totalProgress))
                .stroke(backgroundTheme.glowColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(dashboard.totalProgress * 100))%")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 132, height: 132)
    }

    private var actionCard: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Quick actions")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(quickActionSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        if isPrayerTimingEnabled {
                            ActionButtonView(
                                title: "Prayer Timer",
                                icon: "timer",
                                tint: backgroundTheme.glowColor
                            ) {
                                isShowingPrayerTimer = true
                            }
                        }

                        ActionButtonView(
                            title: "Quick Prayer",
                            icon: "hands.sparkles",
                            tint: .teal
                        ) {
                            isShowingQuickPrayer = true
                        }
                    }

                    ActionButtonView(
                        title: "Add Log",
                        icon: "plus.circle.fill",
                        tint: backgroundTheme.glowColor
                    ) {
                        isShowingAddView = true
                    }
                }
            }
        }
    }

    private var sectionsHeader: some View {
        HStack {
            Text("Focus areas")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var recentActivityCard: some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent activity")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Latest logs from your timeline")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !recentEntries.isEmpty {
                    Text("\(recentEntries.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                    }
                }

                if recentEntries.isEmpty {
                    emptyActivityState
                } else {
                    VStack(spacing: 0) {
                        ForEach(recentEntries) { entry in
                            RecentActivityRow(entry: entry, showsPrayerTiming: isPrayerTimingEnabled)

                            if entry.id != recentEntries.last?.id {
                                Divider()
                                    .padding(.leading, 46)
                            }
                        }
                    }
                }
            }
        }
    }

    private var latestActivitySummary: String {
        guard let latest = recentEntries.first else {
            return "No recent logs"
        }

        let detail = latest.sinTitle ?? latest.sectionTitle
        return "\(latest.kind.title) • \(detail)"
    }

    private var latestActivityIcon: String {
        recentEntries.first?.kind.symbolName ?? "clock.arrow.circlepath"
    }

    private var emptyActivityState: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text("No activity yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Your prayer sessions and log entries will appear here after you add them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private struct RecentActivityRow: View {
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
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showsPrayerTiming && entry.prayerDurationSeconds > 0 {
                    Text("\(entry.prayerDurationText) prayer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(entry.kind.tint)
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
    HeadwayView(backgroundTheme: .constant(.blood), dashboard: .constant(DashboardViewModel()), logEntries: .constant([]))
}

private extension HeadwayView {
    static let subtitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
}

#Playground {
    print()
}
