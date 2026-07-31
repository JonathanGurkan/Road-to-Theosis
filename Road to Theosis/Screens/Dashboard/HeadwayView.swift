import SwiftUI

struct HeadwayView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    let showVictorySwipeAction: Bool
    @State var isShowingAddView = false
    @State var isShowingQuickPrayer = false
    @State var isShowingPrayerTimer = false
    @State var isCustomizingHome = false
    @State var homeGridWidth: CGFloat = 0
    @State var draggingHomeCardID: HomeScreenCardID?
    @State var selectedDefenseItem: SinCategory?
    @AppStorage(HomeScreenLayout.storageKey) var homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
    @AppStorage("compactSinRows") private var compactSinRows = false
    @AppStorage("isPrayerTimingEnabled") private var isPrayerTimingEnabled = true
    @AppStorage("enableVerseInventory") private var enableVerseInventory = true
    @AppStorage("prayerTimerCountingMode") private var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue

    private var isDaytime: Bool {
        (5..<17).contains(Calendar.current.component(.hour, from: Date()))
    }
    
    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        PrayerTimerCountingMode(rawValue: prayerTimerCountingModeRaw) ?? .foreground
    }

    var homeScreenLayout: HomeScreenLayout {
        HomeScreenLayout.decoded(from: homeScreenLayoutData)
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
        guard isPrayerTimingEnabled else {
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

    private func simulateDailyProgress() {
        dashboard.advanceDailyProgress()
    }

    private func logSwipeOutcome(_ kind: LogEntry.Kind, for itemID: SinCategory.ID, in sectionIndex: Int) -> Bool {
        guard dashboard.sections.indices.contains(sectionIndex),
              let item = dashboard.sections[sectionIndex].items.first(where: { $0.id == itemID }),
              shouldRecordSwipeOutcome(kind, progress: item.progress) else {
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
        logEntries.insert(entry, at: 0)
        return true
    }

    private func shouldRecordSwipeOutcome(_ kind: LogEntry.Kind, progress: Double) -> Bool {
        switch kind {
        case .victory:
            return progress < 1
        case .loss:
            return progress > 0
        case .prayer, .quickPrayer, .progressUpdate, .note:
            return true
        }
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
                            simulateDailyProgress()
                        } label: {
                            Text("Sim Day")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
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
                        Text("\(dashboard.dailyCheckIns) checks • \(dashboard.activeStreak)d streak")
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
            if isPrayerTimingEnabled {
                overviewStackedStat(title: "Prayer minutes", value: "\(dashboard.prayerMinutes)m", icon: "hands.sparkles")

                Divider()
                    .padding(.leading, 38)
            }

            overviewStackedStat(title: "Check-ins", value: "\(dashboard.dailyCheckIns)", icon: "checklist")

            Divider()
                .padding(.leading, 38)

            overviewStackedStat(title: "Active streak", value: "\(dashboard.activeStreak)d", icon: "flame.fill")
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
                            if isPrayerTimingEnabled {
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
                            if isPrayerTimingEnabled {
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
        }
        .padding(.horizontal, 2)
    }

    private var focusAreasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionsHeader

            LazyVStack(spacing: compactSinRows ? 10 : 12) {
                ForEach(dashboard.sections.indices, id: \.self) { index in
                    SinSectionCardView(
                        section: $dashboard.sections[index],
                        isCompact: compactSinRows,
                        showsVictoryAction: showVictorySwipeAction,
                        onShowVerses: { item in
                            selectedDefenseItem = item
                        },
                        onVictory: { itemID in
                            guard logSwipeOutcome(.victory, for: itemID, in: index) else { return }
                            dashboard.markVictory(in: itemID)
                        },
                        onReset: { itemID in
                            guard logSwipeOutcome(.loss, for: itemID, in: index) else { return }
                            dashboard.resetItem(itemID)
                        }
                    )
                }
            }
        }
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

                                        if isPrayerTimingEnabled && entry.prayerDurationSeconds > 0 {
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
            showVictorySwipeAction: true
        )
    }
}

