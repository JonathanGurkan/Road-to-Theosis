import SwiftUI

private struct FocusWidgetPresentation {
    let watchedContexts: [FocusedSinContext]
    let suggestedContexts: [FocusedSinContext]
}

struct HeadwayView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) var preferences
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @Binding var purityCalculationDate: Date
    let onSaveEntry: (LogEntry) -> Void
    @State var isShowingAddView = false
    @State var isShowingQuickPrayer = false
    @State var isShowingPrayerTimer = false
    @State var isCustomizingHome = false
    @State var homeGridWidth: CGFloat = 0
    @State var draggingHomeCardID: HomeScreenCardID?
    @State var selectedDefenseItem: SinCategory?
    @State private var pendingProgressLog: ProgressLogDraft?
    @State var focusedSinIDs: [SinCategory.ID] = []
    @State private var focusWidgetPageID: SinCategory.ID?
    @State private var isShowingModeToggleLabel = false
    @State private var isShowingCheckIn = false
    @State private var greetingWeather: GreetingWeather?
    private let greetingWeatherService = GreetingWeatherService()
    private let maxFocusedSinCount = 3

    private var isDaytime: Bool {
        (5..<17).contains(Calendar.current.component(.hour, from: Date()))
    }
    
    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        PrayerTimerCountingMode(rawValue: preferences.prayerTimerCountingModeRaw) ?? .foreground
    }

    private var focusSliderStyle: FocusSliderStyle {
        FocusSliderStyle(rawValue: preferences.focusSliderStyleRaw) ?? .clean
    }

    private var purityStrictness: PurityStrictness {
        PurityStrictness(rawValue: preferences.purityStrictnessRaw) ?? .normal
    }

    private var greetingWeatherThresholds: GreetingWeatherThresholds {
        GreetingWeatherThresholds(
            warmThresholdCelsius: preferences.greetingWeatherWarmThresholdCelsius,
            coldThresholdCelsius: preferences.greetingWeatherColdThresholdCelsius,
            breezyThresholdKilometersPerHour: preferences.greetingWeatherBreezyThresholdKilometersPerHour
        )
    }

    private var greetingWeatherSettingsSignature: String {
        [
            String(preferences.isGreetingWeatherEnabled),
            String(preferences.greetingWeatherWarmThresholdCelsius),
            String(preferences.greetingWeatherColdThresholdCelsius),
            String(preferences.greetingWeatherBreezyThresholdKilometersPerHour)
        ].joined(separator: "|")
    }

    var homeScreenLayout: HomeScreenLayout {
        HomeScreenLayout.decoded(from: preferences.homeScreenLayoutData)
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
    
    private var greetingSubtitle: String {
        Self.greetingSubtitle(for: .now)
    }
    
    private static func greetingSubtitle(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        
        switch hour {
        case 5..<12:
            return "Hopefully you slept well today. Let's start the day with prayer and progress through this blessed day on the path of righteousness. Don't forget to put on the full armor of God!"
        case 12..<17:
            return "Hopefully the day is going pretty well so far. Take a moment to be mindfull of all your blessings so far!"
        case 17..<22:
            return "Don't forget to be mindfull of your blessings throughout the day so far. God is with you!"
        default:
            return "The day is coming to an end. Let's take some time to thank God for today's blessings and reflect on anything that need to be confessed and prayed for."
        }
    }

    private var progressSubtitle: String {
        Self.subtitleFormatter.string(from: Date())
    }


    private var quickActionSubtitle: String {
        guard preferences.isPrayerTimingEnabled else {
            return "Add a prayer, victory, loss, or note."
        }

        switch prayerTimerCountingMode {
        case .foreground:
            return "Start a quiet prayer session or add a victory, loss, or note."
        case .background:
            return "Start a prayer session that can keep counting in the background, or add a victory, loss, or note."
        }
    }

    private var recentEntries: [LogEntry] {
        recentEntries(limit: 3)
    }

    private func recentEntries(limit: Int) -> [LogEntry] {
        Array(logEntries.sorted { $0.occurredAt > $1.occurredAt }.prefix(limit))
    }

    private func refreshGreetingWeather() async {
        guard preferences.isGreetingWeatherEnabled else {
            greetingWeather = nil
            return
        }

        greetingWeather = await greetingWeatherService.currentWeather(thresholds: greetingWeatherThresholds)
    }

    private func startCheckIn() {
        isShowingCheckIn = true
    }

    private func saveEntry(_ entry: LogEntry, now: Date? = nil) {
        onSaveEntry(entry)

        if let now {
            purityCalculationDate = max(now, entry.occurredAt)
            recalculatePurity(now: purityCalculationDate)
        }
    }

    private func recalculatePurity(now: Date? = nil) {
        dashboard.recalculatePurity(from: logEntries, now: now ?? purityCalculationDate, strictness: purityStrictness)
    }

    private func logSwipeOutcome(_ kind: LogEntry.Kind, for itemID: SinCategory.ID, in sectionIndex: Int) -> Bool {
        guard dashboard.sections.indices.contains(sectionIndex),
              let item = dashboard.sections[sectionIndex].items.first(where: { $0.id == itemID }) else {
            return false
        }

        let entry = LogEntry(
            kind: kind,
            sectionTitle: dashboard.sections[sectionIndex].title,
            sinTitle: item.title,
            note: "",
            prayerMinutes: 0,
            occurredAt: Date()
        )
        saveEntry(entry)
        return true
    }

    private var selectedFocusContexts: [FocusedSinContext] {
        focusedSinIDs.compactMap { focusContext(for: $0) }
    }

    private var activeFocusIDs: Set<SinCategory.ID> {
        Set(selectedFocusContexts.map { $0.item.id })
    }

    private func focusWidgetPresentation(watchedLimit: Int, suggestionLimit: Int) -> FocusWidgetPresentation {
        let watchedContexts = Array(selectedFocusContexts.prefix(watchedLimit))
        let watchedIDs = Set(watchedContexts.map { $0.item.id })
        let suggestedContexts = Array(
            rankedFocusContexts(excluding: watchedIDs)
                .prefix(suggestionLimit)
        )

        return FocusWidgetPresentation(
            watchedContexts: watchedContexts,
            suggestedContexts: suggestedContexts
        )
    }

    private func focusSuggestionLimit(for size: HomeScreenCardSize) -> Int {
        switch size {
        case .minimal:
            return 0
        case .compact:
            return 3
        case .standard:
            return 8
        }
    }

    private func rankedFocusContexts(excluding excludedIDs: Set<SinCategory.ID> = []) -> [FocusedSinContext] {
        dashboard.sections.indices
            .flatMap { sectionIndex in
                dashboard.sections[sectionIndex].items.indices.map { itemIndex in
                    FocusedSinContext(
                        sectionIndex: sectionIndex,
                        itemIndex: itemIndex,
                        sectionTitle: dashboard.sections[sectionIndex].title,
                        item: dashboard.sections[sectionIndex].items[itemIndex]
                    )
                }
            }
            .filter { !excludedIDs.contains($0.item.id) }
            .sorted { first, second in
                first.item.progress < second.item.progress
            }
    }

    private func focusContext(for itemID: SinCategory.ID) -> FocusedSinContext? {
        for sectionIndex in dashboard.sections.indices {
            guard let itemIndex = dashboard.sections[sectionIndex].items.firstIndex(where: { $0.id == itemID }) else {
                continue
            }

            return FocusedSinContext(
                sectionIndex: sectionIndex,
                itemIndex: itemIndex,
                sectionTitle: dashboard.sections[sectionIndex].title,
                item: dashboard.sections[sectionIndex].items[itemIndex]
            )
        }

        return nil
    }

    private func focusContext(for reference: FocusedSinReference) -> FocusedSinContext? {
        for sectionIndex in dashboard.sections.indices where dashboard.sections[sectionIndex].title == reference.sectionTitle {
            guard let itemIndex = dashboard.sections[sectionIndex].items.firstIndex(where: { $0.title == reference.sinTitle }) else {
                return nil
            }

            return FocusedSinContext(
                sectionIndex: sectionIndex,
                itemIndex: itemIndex,
                sectionTitle: dashboard.sections[sectionIndex].title,
                item: dashboard.sections[sectionIndex].items[itemIndex]
            )
        }

        return nil
    }

    private func restoreFocusedSinIDs() {
        guard let data = preferences.focusedSinReferences.data(using: .utf8),
              let references = try? JSONDecoder().decode([FocusedSinReference].self, from: data) else {
            focusedSinIDs = []
            return
        }

        focusedSinIDs = references.compactMap { focusContext(for: $0)?.item.id }
    }

    private func persistFocusedSinIDs() {
        let references = selectedFocusContexts.map {
            FocusedSinReference(sectionTitle: $0.sectionTitle, sinTitle: $0.item.title)
        }

        guard let data = try? JSONEncoder().encode(references),
              let encoded = String(data: data, encoding: .utf8) else {
            return
        }

        preferences.focusedSinReferences = encoded
    }

    private func logFocusedOutcome(_ kind: LogEntry.Kind, context: FocusedSinContext) {
        guard logSwipeOutcome(kind, for: context.item.id, in: context.sectionIndex) else { return }

        // Purity is recalculated from the saved log entry in logSwipeOutcome.
    }

    private func logFocusedPrayer(context: FocusedSinContext) {
        let entry = LogEntry(
            kind: .quickPrayer,
            sectionTitle: context.sectionTitle,
            sinTitle: context.item.title,
            note: "",
            prayerMinutes: 1,
            occurredAt: Date()
        )
        saveEntry(entry)
    }

    private func toggleFocus(for itemID: SinCategory.ID) {
        if focusedSinIDs.contains(itemID) {
            focusedSinIDs.removeAll { $0 == itemID }
            return
        }

        if focusedSinIDs.count >= maxFocusedSinCount {
            focusedSinIDs.removeFirst()
        }

        focusedSinIDs.append(itemID)
    }

    private func prepareProgressLog(for itemID: SinCategory.ID, progress: Double, in sectionIndex: Int) {
        guard dashboard.sections.indices.contains(sectionIndex),
              let item = dashboard.sections[sectionIndex].items.first(where: { $0.id == itemID }) else {
            return
        }

        let percentage = SinFrequencyScale.percentage(for: progress)
        dashboard.setProgress(Double(percentage) / 100, for: itemID)
        pendingProgressLog = ProgressLogDraft(
            sectionTitle: dashboard.sections[sectionIndex].title,
            sinTitle: item.title,
            progressPercentage: percentage,
            tint: item.tint
        )
    }

    private func saveProgressLog(_ draft: ProgressLogDraft, note: String) {
        let fallbackNote = "Adjusted purity to \(SinFrequencyScale.label(for: draft.progressPercentage))"
        let entry = LogEntry(
            kind: .sliderProgressUpdate,
            sectionTitle: draft.sectionTitle,
            sinTitle: draft.sinTitle,
            note: note.isEmpty ? fallbackNote : note,
            prayerMinutes: 0,
            progressPercentage: draft.progressPercentage,
            occurredAt: Date()
        )
        saveEntry(entry)
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: isCustomizingHome ? 14 : 16) {
                    HomeScreenGridLayout(horizontalSpacing: HomeScreenGridLayout.defaultHorizontalSpacing, verticalSpacing: HomeScreenGridLayout.defaultVerticalSpacing) {
                        ForEach(homeScreenLayout.cards) { configuration in
                            editableHomeCard(for: configuration)
                                .layoutValue(key: HomeScreenGridWidthUnitsKey.self, value: configuration.id.supportsResizing ? configuration.size.widthUnits : 4)
                                .layoutValue(key: HomeScreenGridHeightUnitsKey.self, value: configuration.id.supportsResizing ? configuration.size.heightUnits : 2)
                                .layoutValue(key: HomeScreenGridUsesFixedHeightKey.self, value: configuration.id.supportsResizing && configuration.size.usesFixedGridHeight)
                        }
                    }
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    homeGridWidth = proxy.size.width
                                }
                                .onChange(of: proxy.size.width) { _, width in
                                    homeGridWidth = width
                                }
                        }
                    }
                    .dropDestination(for: String.self) { droppedIDs, location in
                        guard isCustomizingHome,
                              let rawValue = droppedIDs.first,
                              let sourceID = HomeScreenCardID(rawValue: rawValue) else {
                            return false
                        }

                        moveHomeCard(sourceID, toGridLocation: location)
                        return true
                    }

                    if isCustomizingHome {
                        addCardsArea
                    }
                }
                .animation(.snappy, value: homeScreenLayout)
                .animation(.snappy, value: isCustomizingHome)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("My Journey")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isCustomizingHome.toggle()
                } label: {
                    Text(isCustomizingHome ? "Done" : "Edit")
                        .font(.subheadline.weight(.semibold))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if isCustomizingHome {
                    addWidgetToolbarMenu
                } else {
                    HStack(spacing: 12) {
                        Button {
                            startCheckIn()
                        } label: {
                            Label("Check-in", systemImage: "calendar.badge.checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(backgroundTheme.glowColor)
                        }
                        Button {
                            isShowingAddView.toggle()
                        } label: {
                            Label("Add Log", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
        }
        .onAppear(perform: restoreFocusedSinIDs)
        .onChange(of: focusedSinIDs) { _, _ in
            persistFocusedSinIDs()
        }
        .onChange(of: preferences.focusedSinReferences) { _, _ in
            restoreFocusedSinIDs()
        }
        .sheet(isPresented: $isShowingAddView) {
            AddLoggingView(backgroundTheme: $backgroundTheme) { entry in
                saveEntry(entry)
            }
        }
        .sheet(isPresented: $isShowingQuickPrayer) {
            AddLoggingView(backgroundTheme: $backgroundTheme, onSave: { entry in
                saveEntry(entry)
            }, initialMode: .quickPrayer)
        }
        .onChange(of: preferences.isPrayerTimingEnabled) { _, isEnabled in
            if !isEnabled {
                isShowingPrayerTimer = false
            }
        }
        .fullScreenCover(isPresented: $isShowingPrayerTimer) {
            PrayerTimerView(backgroundTheme: $backgroundTheme) { entry in
                saveEntry(entry)
            }
        }
        .sheet(item: $selectedDefenseItem) { item in
            DefenseVersesSheetView(category: item)
        }
        .sheet(item: $pendingProgressLog) { draft in
            ProgressLogSheetView(backgroundTheme: $backgroundTheme, draft: draft) { note in
                saveProgressLog(draft, note: note)
            }
        }
        .fullScreenCover(isPresented: $isShowingCheckIn) {
            CheckInView(
                backgroundTheme: $backgroundTheme,
                dashboard: dashboard,
                onSave: { entry in
                    saveEntry(entry)
                }
            )
        }
    }

    @ViewBuilder
    func homeCard(for configuration: HomeScreenCardConfiguration) -> some View {
        switch configuration.id {
        case .greeting:
            headerCard(size: configuration.size)
        case .overview:
            overviewCard(size: configuration.size)
        case .quickActions:
            actionCard(size: configuration.size)
        case .recentActivity:
            recentActivityCard(size: configuration.size)
        case .focusWidget:
            focusWidgetCard(size: configuration.size)
        case .focusAreas:
            focusAreasCard
        }
    }

    private func headerCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16, fillsAvailableHeight: size.usesFixedGridHeight) {
            switch size {
            case .minimal:
                ZStack(alignment: .topLeading) {
                    HStack {
                        minimalIcon(isDaytime ? "sun.max.fill" : "moon.stars.fill", size: 20)
                        Text(greeting)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.56)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 1) {
                        Spacer()
                        Text(progressSubtitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Spacer()
                        Text(isDaytime ? "Enjoy your day's blessings!" : "Hopefully the day is going great. Enjoy the evening!")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text(greeting)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 0)

                    Text(greetingSubtitle)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .lineLimit(8)
                        .minimumScaleFactor(0.68)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .standard:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)
                        Text(progressSubtitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }

                    Text(greeting)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(greetingSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func overviewCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16, fillsAvailableHeight: size.usesFixedGridHeight) {
            switch size {
            case .minimal:
                ZStack(alignment: .topLeading) {
                    HStack {
                        minimalIcon("chart.line.uptrend.xyaxis", size: 20)
                        Text("Progress")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.56)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 1) {
                        Spacer(minLength: 3)
                        Text("\(Int(dashboard.totalProgress * 100))%")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.bottom, 5)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.10))
                                Capsule()
                                    .fill(backgroundTheme.glowColor)
                                    .frame(width: proxy.size.width * min(max(dashboard.totalProgress, 0), 1))
                            }
                            Spacer()
                        }
                        .frame(height: 4)
                        Text("\(dashboard.dailyCheckIns) checks • \(dashboard.overallResistanceCount) resist")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .padding(.top, 3)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text("Daily overview")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 0)

                    Text("\(Int(dashboard.totalProgress * 100))%")
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    compactProgressBar

                    HStack(spacing: 6) {
                        compactOverviewInfoPill(value: "\(dashboard.dailyCheckIns)", label: "Checks", icon: "checklist")
                        compactOverviewInfoPill(value: "\(dashboard.activeStreak)d", label: "Streak", icon: "flame.fill")
                        compactOverviewInfoPill(value: "\(dashboard.overallResistanceCount)", label: "Resist", icon: "checkmark.shield.fill")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .standard:
                HStack(alignment: .center, spacing: 16) {
                    progressRing

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily overview")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text("Your current direction today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        overviewStackedStats
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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

            VStack {
                Text("Progress")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text("\(Int(dashboard.totalProgress * 100))%")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: 116, height: 116)
    }

    private var compactProgressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.10))

                Capsule()
                    .fill(backgroundTheme.glowColor)
                    .frame(width: proxy.size.width * min(max(dashboard.totalProgress, 0), 1))
            }
        }
        .frame(height: 8)
    }

    private func minimalIcon(_ systemName: String, size: CGFloat = 24) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(backgroundTheme.glowColor)
            .frame(width: size, height: size)
            .background(backgroundTheme.glowColor.opacity(0.14), in: Circle())
    }

    private func compactOverviewInfoPill(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(backgroundTheme.glowColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.76)
        }
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .background(backgroundTheme.glowColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var overviewStackedStats: some View {
        VStack(spacing: 3) {
            if preferences.isPrayerTimingEnabled {
                overviewStackedStat(title: "Prayer minutes", value: "\(dashboard.prayerMinutes)m", icon: "hands.sparkles")

                Divider()
                    .padding(.leading, 38)
            }

            overviewStackedStat(title: "Check-ins", value: "\(dashboard.dailyCheckIns)", icon: "checklist")

            Divider()
                .padding(.leading, 38)

            overviewStackedStat(title: "Active streak", value: "\(dashboard.activeStreak)d", icon: "flame.fill")

            Divider()
                .padding(.leading, 38)

            overviewStackedStat(title: "Overall resistance", value: "\(dashboard.overallResistanceCount)", icon: "checkmark.shield.fill")
        }
    }

    private func overviewStackedStat(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(backgroundTheme.glowColor)
                .frame(width: 28, height: 28)
                .background(backgroundTheme.glowColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(value)
                    .font(.headline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 34)
    }

    private func actionCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16, fillsAvailableHeight: size.usesFixedGridHeight) {
            switch size {
            case .minimal:
                ZStack(alignment: .topLeading) {
                    HStack {
                        minimalIcon("bolt.fill", size: 20)
                        Text("Actions")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.56)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 1) {
                        Spacer()
                        HStack(spacing: 6) {
                            if preferences.isPrayerTimingEnabled {
                                compactActionButton(icon: "timer", tint: backgroundTheme.glowColor, size: 36) {
                                    isShowingPrayerTimer = true
                                }
                            }

                            compactActionButton(icon: "hands.sparkles", tint: .white, size: 36) {
                                isShowingQuickPrayer = true
                            }

                            compactActionButton(icon: "plus.circle.fill", tint: backgroundTheme.glowColor, size: 36) {
                                isShowingAddView = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text("Quick actions")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            if preferences.isPrayerTimingEnabled {
                                compactActionRowButton(title: "Timer", icon: "timer", tint: backgroundTheme.glowColor, minHeight: 46) {
                                    isShowingPrayerTimer = true
                                }
                            }

                            compactActionRowButton(title: "Prayer", icon: "hands.sparkles", tint: .white, minHeight: 46) {
                                isShowingQuickPrayer = true
                            }
                        }

                        compactActionRowButton(title: "Add Log", icon: "plus.circle.fill", tint: backgroundTheme.glowColor, minHeight: 46) {
                            isShowingAddView = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .standard:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick actions")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(quickActionSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            if preferences.isPrayerTimingEnabled {
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
                                tint: .white
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
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }

    private func compactActionButton(icon: String, tint: Color, size: CGFloat = 24, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: size + 8, height: size)
                .background(tint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func compactActionRowButton(title: String, icon: String, tint: Color, minHeight: CGFloat = 30, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var sectionsHeader: some View {
        HStack {
            Text("My focus areas")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    preferences.usesFocusProgressSliders.toggle()
                    isShowingModeToggleLabel = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        isShowingModeToggleLabel = false
                    }
                }
            } label: {
                HStack(spacing: isShowingModeToggleLabel ? 6 : 0) {
                    Image(systemName: preferences.usesFocusProgressSliders ? "slider.horizontal.3" : "chart.bar.fill")
                        .font(.caption.weight(.semibold))

                    if isShowingModeToggleLabel {
                        Text(preferences.usesFocusProgressSliders ? "Slider" : "Bar")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
                    }
                }
                .foregroundStyle(backgroundTheme.glowColor)
                .padding(.horizontal, isShowingModeToggleLabel ? 10 : 0)
                .frame(width: isShowingModeToggleLabel ? 78 : 28, height: 28)
                .background(backgroundTheme.glowColor.opacity(0.14), in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isShowingModeToggleLabel)
            .accessibilityLabel(preferences.usesFocusProgressSliders ? "Current mode: slider" : "Current mode: bar")
        }
        .padding(.horizontal, 2)
    }

    private var focusAreasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionsHeader

            LazyVStack(spacing: preferences.compactSinRows ? 10 : 12) {
                ForEach(dashboard.sections.indices, id: \.self) { index in
                    SinSectionCardView(
                        section: $dashboard.sections[index],
                        isCompact: preferences.compactSinRows,
                        showsVictoryAction: true,
                        usesProgressSliders: preferences.usesFocusProgressSliders,
                        sliderStyle: focusSliderStyle,
                        focusedItemIDs: activeFocusIDs,
                        onShowVerses: { item in
                            selectedDefenseItem = item
                        },
                        onFocus: { itemID in
                            toggleFocus(for: itemID)
                        },
                        onVictory: { itemID in
                            _ = logSwipeOutcome(.victory, for: itemID, in: index)
                        },
                        onReset: { itemID in
                            _ = logSwipeOutcome(.loss, for: itemID, in: index)
                        },
                        onProgressChanged: { itemID, progress in
                            prepareProgressLog(for: itemID, progress: progress, in: index)
                        }
                    )
                }
            }
        }
    }

    private func focusWidgetCard(size: HomeScreenCardSize) -> some View {
        let presentation = focusWidgetPresentation(
            watchedLimit: maxFocusedSinCount,
            suggestionLimit: focusSuggestionLimit(for: size)
        )
        let selectedFocusID = focusWidgetPageID ?? presentation.watchedContexts.first?.item.id
        let selectedFocusIndex = presentation.watchedContexts.firstIndex { $0.item.id == selectedFocusID }
            .map { $0 + 1 } ?? (presentation.watchedContexts.isEmpty ? 0 : 1)

        return AppSurfaceCard(contentPadding: size == .minimal ? 8 : 14, fillsAvailableHeight: size.usesFixedGridHeight) {
            VStack(alignment: .leading, spacing: size == .minimal ? 6 : 12) {
                HStack(spacing: 8) {
                    minimalIcon("scope", size: size == .minimal ? 18 : 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(size == .standard ? "Focus watch" : "Focus")
                            .font((size == .minimal ? Font.subheadline : Font.title3).weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if size == .standard {
                            Text("Work a few struggles with prayer and watchfulness.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                        }
                    }

                    Spacer(minLength: 8)
                    if size != .standard {
                        Text("\(selectedFocusIndex)/\(maxFocusedSinCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, size == .minimal ? 6 : 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.07), in: Capsule())
                    }
                }

                switch size {
                case .minimal:
                    if presentation.watchedContexts.isEmpty {
                        focusWidgetEmptyMessage(isMinimal: true)
                    } else {
                        focusWidgetPager(contexts: presentation.watchedContexts, size: size)
                    }
                case .compact:
                    focusWidgetCompactContent(presentation)
                case .standard:
                    focusWidgetStandardContent(presentation)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func focusWidgetCompactContent(_ presentation: FocusWidgetPresentation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if presentation.watchedContexts.isEmpty {
                focusWidgetEmptyMessage(isMinimal: false)
            } else {
                focusWidgetPager(contexts: presentation.watchedContexts, size: .compact)
            }

            if !presentation.suggestedContexts.isEmpty {
                focusSuggestionsList(presentation.suggestedContexts, isCompact: true)
            }
        }
    }

    private func focusWidgetStandardContent(_ presentation: FocusWidgetPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if presentation.watchedContexts.isEmpty {
                focusWidgetEmptyMessage(isMinimal: false)
                    .frame(maxWidth: .infinity, minHeight: 102, alignment: .center)
            } else {
                VStack(spacing: 8) {
                    ForEach(presentation.watchedContexts, id: \.item.id) { context in
                        focusWidgetRow(
                            for: context,
                            isWatched: true,
                            isDense: false,
                            showsActions: true
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            if !presentation.suggestedContexts.isEmpty {
                focusSuggestionsList(presentation.suggestedContexts, isCompact: false)
            }
        }
    }

    private func focusWidgetPager(contexts: [FocusedSinContext], size: HomeScreenCardSize) -> some View {
        let selectedID = focusWidgetPageID ?? contexts.first?.item.id

        return VStack(spacing: size == .minimal ? 3 : 6) {
            TabView(selection: $focusWidgetPageID) {
                ForEach(contexts, id: \.item.id) { context in
                    focusWidgetPage(for: context, size: size)
                        .tag(Optional(context.item.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if focusWidgetPageID == nil {
                    focusWidgetPageID = contexts.first?.item.id
                }
            }
            .onChange(of: contexts.map { $0.item.id }) { _, itemIDs in
                if let focusWidgetPageID, itemIDs.contains(focusWidgetPageID) {
                    return
                }

                focusWidgetPageID = itemIDs.first
            }

            focusWidgetPageIndicator(contexts: contexts, selectedID: selectedID)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func focusWidgetPage(for context: FocusedSinContext, size: HomeScreenCardSize) -> some View {
        let isMinimal = size == .minimal
        let iconSize: CGFloat = isMinimal ? 20 : 28

        return VStack(alignment: .leading, spacing: isMinimal ? 5 : 8) {
            HStack(alignment: .center, spacing: isMinimal ? 7 : 10) {
                ZStack {
                    Circle()
                        .fill(context.item.tint.opacity(0.16))

                    Image(systemName: context.item.icon)
                        .font((isMinimal ? Font.caption2 : Font.caption).weight(.semibold))
                        .foregroundStyle(context.item.tint)
                }
                .frame(width: iconSize, height: iconSize)

                VStack(alignment: .leading, spacing: 1) {
                    Text(context.item.title)
                        .font((isMinimal ? Font.caption : Font.subheadline).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(context.item.watchword)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                Text("\(Int(context.item.progress * 100))%")
                    .font((isMinimal ? Font.caption2 : Font.caption).weight(.bold))
                    .foregroundStyle(context.item.tint)
            }

            ProgressView(value: context.item.progress)
                .tint(context.item.tint)
                .scaleEffect(x: 1, y: isMinimal ? 0.65 : 0.82, anchor: .center)

            if !isMinimal {
                Text(context.sectionTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(isMinimal ? 7 : 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func focusWidgetPageIndicator(contexts: [FocusedSinContext], selectedID: SinCategory.ID?) -> some View {
        HStack(spacing: 5) {
            ForEach(contexts, id: \.item.id) { context in
                Circle()
                    .fill(context.item.id == selectedID ? context.item.tint : Color.primary.opacity(0.18))
                    .frame(width: context.item.id == selectedID ? 6 : 5, height: context.item.id == selectedID ? 6 : 5)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func focusWidgetRow(for context: FocusedSinContext, isWatched: Bool, isDense: Bool, showsActions: Bool) -> some View {
        let iconSize: CGFloat = isDense ? 24 : 30

        return VStack(alignment: .leading, spacing: isDense ? 6 : 8) {
            HStack(alignment: .center, spacing: isDense ? 8 : 10) {
                ZStack {
                    Circle()
                        .fill(context.item.tint.opacity(0.16))

                    Image(systemName: context.item.icon)
                        .font((isDense ? Font.caption2 : Font.caption).weight(.semibold))
                        .foregroundStyle(context.item.tint)
                }
                .frame(width: iconSize, height: iconSize)

                VStack(alignment: .leading, spacing: 1) {
                    Text(context.item.title)
                        .font((isDense ? Font.caption : Font.subheadline).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(context.item.watchword)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(Int(context.item.progress * 100))%")
                    .font((isDense ? Font.caption2 : Font.caption).weight(.bold))
                    .foregroundStyle(context.item.tint)
            }

            ProgressView(value: context.item.progress)
                .tint(context.item.tint)
                .scaleEffect(x: 1, y: isDense ? 0.75 : 1, anchor: .center)

            if showsActions {
                HStack(spacing: 6) {
                    compactActionButton(icon: "shield.lefthalf.filled", tint: .green, size: 22) {
                        logFocusedOutcome(.victory, context: context)
                    }

                    compactActionButton(icon: "exclamationmark.triangle", tint: .red, size: 22) {
                        logFocusedOutcome(.loss, context: context)
                    }

                    compactActionButton(icon: "hands.sparkles", tint: .white, size: 22) {
                        logFocusedPrayer(context: context)
                    }

                    compactActionButton(icon: "book.fill", tint: context.item.tint, size: 22) {
                        selectedDefenseItem = context.item
                    }

                    Spacer(minLength: 0)

                    Button {
                        toggleFocus(for: context.item.id)
                    } label: {
                        Text(isWatched ? "Focussing" : "Focus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isWatched ? .white : context.item.tint)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 28)
                            .background(isWatched ? context.item.tint : context.item.tint.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isWatched ? "Remove \(context.item.title) from today's focus" : "Set \(context.item.title) as today's focus")
                }
            }
        }
        .padding(isDense ? 8 : 10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func focusWidgetEmptyMessage(isMinimal: Bool) -> some View {
        Text("No focus yet. Add one.")
            .font((isMinimal ? Font.caption : Font.subheadline).weight(.semibold))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: isMinimal ? 0 : 44, maxHeight: isMinimal ? .infinity : nil, alignment: .center)
            .padding(isMinimal ? 6 : 10)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func focusSuggestionsList(_ suggestedContexts: [FocusedSinContext], isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            Text("Suggestions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                spacing: 6
            ) {
                ForEach(suggestedContexts, id: \.item.id) { context in
                    focusSuggestionButton(for: context, isCompact: isCompact)
                }
            }
        }
    }

    private func focusSuggestionButton(for context: FocusedSinContext, isCompact: Bool) -> some View {
        Button {
            toggleFocus(for: context.item.id)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: context.item.icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(context.item.tint)
                    .frame(width: 18, height: 18)
                    .background(context.item.tint.opacity(0.14), in: Circle())

                Text(context.item.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 4)

                Text("\(Int(context.item.progress * 100))%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(context.item.tint)
                    .monospacedDigit()
            }
            .padding(.horizontal, isCompact ? 7 : 8)
            .padding(.vertical, isCompact ? 5 : 6)
            .frame(maxWidth: .infinity, minHeight: isCompact ? 30 : 34, alignment: .leading)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set \(context.item.title) as today's focus")
    }

    private func recentActivityCard(size: HomeScreenCardSize) -> some View {
        let entries = recentEntries(limit: size == .minimal ? 1 : 2)

        return AppSurfaceCard(contentPadding: size == .minimal ? 8 : 14, fillsAvailableHeight: size.usesFixedGridHeight) {
            switch size {
            case .minimal:
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        minimalIcon("clock.arrow.circlepath", size: 20)
                        Text("Recent")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    if let entry = entries.first {
                        compactRecentActivityRow(
                            title: entry.kind.title,
                            detail: entry.sinTitle ?? entry.sectionTitle,
                            icon: entry.kind.symbolName,
                            tint: entry.kind.tint
                        )
                    } else {
                        compactRecentActivityRow(title: "No logs", detail: "Add one", icon: "clock.arrow.circlepath", tint: backgroundTheme.glowColor)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: recentEntries.first?.kind.symbolName ?? "clock.arrow.circlepath")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text("Recent activity")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    VStack(spacing: 6) {
                        if entries.isEmpty {
                            compactRecentActivityRow(title: "No logs", detail: "Add one", icon: "clock.arrow.circlepath", tint: backgroundTheme.glowColor)
                        } else {
                            ForEach(entries) { entry in
                                compactRecentActivityRow(
                                    title: entry.kind.title,
                                    detail: entry.sinTitle ?? entry.sectionTitle,
                                    icon: entry.kind.symbolName,
                                    tint: entry.kind.tint
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .standard:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recent activity")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Latest logs from your timeline")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !entries.isEmpty {
                            Text("\(entries.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.primary.opacity(0.08), in: Capsule())
                        }
                    }

                    if entries.isEmpty {
                        emptyActivityState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(entries) { entry in
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

                                            Text(Self.activityTimeFormatter.string(from: entry.occurredAt))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        if !entry.note.isEmpty {
                                            Text(entry.note)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        if preferences.isPrayerTimingEnabled && entry.prayerDurationSeconds > 0 {
                                            Text("\(entry.prayerDurationText) prayer")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(entry.kind.tint)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)

                                if entry.id != entries.last?.id {
                                    Divider()
                                        .padding(.leading, 46)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func compactRecentActivityRow(for entry: LogEntry) -> some View {
        compactRecentActivityRow(
            title: entry.kind.title,
            detail: recentActivityDetail(for: entry),
            icon: entry.kind.symbolName,
            tint: entry.kind.tint
        )
    }

    private func standardRecentActivityRow(for entry: LogEntry) -> some View {
        compactRecentActivityRow(for: entry)
    }

    private func recentActivityDetail(for entry: LogEntry) -> String {
        if let sinTitle = entry.sinTitle {
            return sinTitle
        }

        if preferences.isPrayerTimingEnabled && entry.prayerDurationSeconds > 0 {
            return "\(entry.prayerDurationText) prayer"
        }

        return entry.sectionTitle
    }

    private func compactRecentActivityRow(title: String, detail: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
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

#Preview {
    NavigationStack {
        HeadwayView(
            backgroundTheme: .constant(.blood),
            dashboard: .constant(DashboardViewModel()),
            logEntries: .constant([]),
            purityCalculationDate: .constant(Date()),
            onSaveEntry: { _ in }
        )
    }
    .environment(AppPreferenceStore())
}
