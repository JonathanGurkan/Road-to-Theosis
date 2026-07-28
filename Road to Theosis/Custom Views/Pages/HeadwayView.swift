import SwiftUI
import Playgrounds

struct HeadwayView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @State private var isShowingAddView = false
    @State private var isShowingQuickPrayer = false
    @State private var isShowingPrayerTimer = false
    @State private var isCustomizingHome = false
    @State private var selectedDefenseItem: SinCategory?
    @AppStorage(HomeScreenLayout.storageKey) private var homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
    @AppStorage("compactSinRows") private var compactSinRows = false
    @AppStorage("isPrayerTimingEnabled") private var isPrayerTimingEnabled = true
    @AppStorage("prayerTimerCountingMode") private var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue

    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        PrayerTimerCountingMode(rawValue: prayerTimerCountingModeRaw) ?? .foreground
    }

    private var homeScreenLayout: HomeScreenLayout {
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

    private var compactWeekday: String {
        Self.compactWeekdayFormatter.string(from: Date()).uppercased()
    }

    private var compactGreeting: String {
        greeting.replacingOccurrences(of: "Good ", with: "")
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

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: isCustomizingHome ? 14 : 16) {
                    HomeScreenGridLayout(horizontalSpacing: 8, verticalSpacing: 4) {
                        ForEach(homeScreenLayout.cards) { configuration in
                            editableHomeCard(for: configuration)
                                .layoutValue(key: HomeScreenGridWidthUnitsKey.self, value: configuration.id.supportsResizing ? configuration.size.widthUnits : 4)
                                .layoutValue(key: HomeScreenGridHeightUnitsKey.self, value: configuration.id.supportsResizing ? configuration.size.heightUnits : 2)
                                .layoutValue(key: HomeScreenGridUsesFixedHeightKey.self, value: configuration.id.supportsResizing)
                        }
                    }

                    if isCustomizingHome {
                        addCardsArea
                    }

                    customizeHomeButton
                }
                .animation(.snappy, value: homeScreenLayout)
                .animation(.snappy, value: isCustomizingHome)
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

    private func editableHomeCard(for configuration: HomeScreenCardConfiguration) -> some View {
        ZStack(alignment: .topLeading) {
            homeCard(for: configuration)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!isCustomizingHome)

            if isCustomizingHome {
                homeCardEditOverlay(for: configuration)
            }
        }
        .draggable(configuration.id.rawValue)
        .dropDestination(for: String.self) { droppedIDs, _ in
            guard isCustomizingHome,
                  let rawValue = droppedIDs.first,
                  let sourceID = HomeScreenCardID(rawValue: rawValue),
                  sourceID != configuration.id else {
                return false
            }

            moveHomeCard(sourceID, before: configuration.id)
            return true
        }
        .onLongPressGesture {
            guard !isCustomizingHome else { return }
            isCustomizingHome = true
        }
    }

    private func homeCardEditOverlay(for configuration: HomeScreenCardConfiguration) -> some View {
        ZStack(alignment: .topLeading) {
            if configuration.id.supportsResizing && configuration.size == .minimal {
                minimalEditMenu(for: configuration)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(5)
            } else {
                Button {
                    removeHomeCard(configuration.id)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3.weight(.semibold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 3)
                }
                .padding(6)

                HStack(spacing: 8) {
                    Spacer()

                    Button {
                        moveHomeCard(configuration.id, by: -1)
                    } label: {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.title3.weight(.semibold))
                    }
                    .disabled(isFirstHomeCard(configuration.id))

                    Button {
                        moveHomeCard(configuration.id, by: 1)
                    } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title3.weight(.semibold))
                    }
                    .disabled(isLastHomeCard(configuration.id))

                    if configuration.id.supportsResizing {
                        Menu {
                            Picker("Size", selection: sizeBinding(for: configuration.id)) {
                                ForEach(HomeScreenCardSize.allCases) { size in
                                    Text(size.title).tag(size)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                                .font(.title3.weight(.semibold))
                        }
                    }
                }
                .foregroundStyle(backgroundTheme.glowColor)
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func minimalEditMenu(for configuration: HomeScreenCardConfiguration) -> some View {
        Menu {
            Button {
                moveHomeCard(configuration.id, by: -1)
            } label: {
                Label("Move Up", systemImage: "chevron.up")
            }
            .disabled(isFirstHomeCard(configuration.id))

            Button {
                moveHomeCard(configuration.id, by: 1)
            } label: {
                Label("Move Down", systemImage: "chevron.down")
            }
            .disabled(isLastHomeCard(configuration.id))

            Picker("Size", selection: sizeBinding(for: configuration.id)) {
                ForEach(HomeScreenCardSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }

            Button(role: .destructive) {
                removeHomeCard(configuration.id)
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(backgroundTheme.glowColor)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
        }
    }

    private var addCardsArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !homeScreenLayout.availableCards.isEmpty {
                Text("Add widgets")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(homeScreenLayout.availableCards) { cardID in
                        Button {
                            addHomeCard(cardID)
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: cardID.systemImage)
                                    .font(.title2.weight(.semibold))
                                Text(cardID.title)
                                    .font(.caption.weight(.semibold))
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.primary.opacity(0.07))
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func homeCard(for configuration: HomeScreenCardConfiguration) -> some View {
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

    private var customizeHomeButton: some View {
        Button {
            isCustomizingHome.toggle()
        } label: {
            Label(isCustomizingHome ? "Done" : "Customize Home Screen", systemImage: isCustomizingHome ? "checkmark.circle.fill" : "slider.horizontal.3")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .ifAvailableGlass(tint: backgroundTheme.glowColor)
    }

    private func updateHomeLayout(_ update: (inout HomeScreenLayout) -> Void) {
        var layout = homeScreenLayout
        update(&layout)
        homeScreenLayoutData = layout.normalized().encoded()
    }

    private func addHomeCard(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            layout.cards.append(HomeScreenCardConfiguration(id: id, size: id.supportsResizing ? .compact : .standard))
        }
    }

    private func removeHomeCard(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            layout.cards.removeAll { $0.id == id }
        }
    }

    private func moveHomeCard(_ id: HomeScreenCardID, by offset: Int) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == id }) else {
                return
            }

            let destinationIndex = min(max(sourceIndex + offset, 0), layout.cards.count - 1)
            guard sourceIndex != destinationIndex else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            layout.cards.insert(card, at: destinationIndex)
        }
    }

    private func moveHomeCard(_ sourceID: HomeScreenCardID, before destinationID: HomeScreenCardID) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == sourceID }),
                  let destinationIndex = layout.cards.firstIndex(where: { $0.id == destinationID }) else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            let adjustedDestinationIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
            layout.cards.insert(card, at: adjustedDestinationIndex)
        }
    }

    private func isFirstHomeCard(_ id: HomeScreenCardID) -> Bool {
        homeScreenLayout.cards.first?.id == id
    }

    private func isLastHomeCard(_ id: HomeScreenCardID) -> Bool {
        homeScreenLayout.cards.last?.id == id
    }

    private func sizeBinding(for id: HomeScreenCardID) -> Binding<HomeScreenCardSize> {
        Binding {
            homeScreenLayout.cards.first(where: { $0.id == id })?.size ?? .standard
        } set: { newSize in
            updateHomeLayout { layout in
                guard let index = layout.cards.firstIndex(where: { $0.id == id }) else {
                    return
                }

                layout.cards[index].size = newSize
            }
        }
    }

    private func headerCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16) {
            switch size {
            case .minimal:
                HStack(spacing: 8) {
                    minimalIcon("sun.max.fill")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(compactWeekday)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(compactGreeting)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(latestActivitySummary)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text(progressSubtitle)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 0)

                    Text(greeting)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(greetingSubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .standard:
                VStack(alignment: .leading, spacing: 8) {
                    Text(progressSubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(greeting)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(greetingSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func overviewCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16) {
            switch size {
            case .minimal:
                HStack(spacing: 8) {
                    minimalIcon("chart.line.uptrend.xyaxis")

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Progress")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("\(Int(dashboard.totalProgress * 100))%")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("\(dashboard.dailyCheckIns) checks • \(dashboard.activeStreak)d")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text("Daily overview")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    progressSummary

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(dashboard.dailyCheckIns) check-ins")
                        Text("\(dashboard.activeStreak)d active streak")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .standard:
                HStack(alignment: .center, spacing: 14) {
                    progressRing(size: size)

                    VStack(alignment: .leading, spacing: 10) {
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

                        overviewStatsStrip
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func progressRing(size: HomeScreenCardSize) -> some View {
        let ringSize: CGFloat = 116

        return ZStack {
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
        .frame(width: ringSize, height: ringSize)
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progress")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(Int(dashboard.totalProgress * 100))%")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    private func minimalIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(backgroundTheme.glowColor)
            .frame(width: 24, height: 24)
            .background(backgroundTheme.glowColor.opacity(0.14), in: Circle())
    }

    private var overviewStatsStrip: some View {
        HStack(spacing: 8) {
            if isPrayerTimingEnabled {
                overviewStatPill(value: "\(dashboard.prayerMinutes)m", icon: "hands.sparkles")
            }

            overviewStatPill(value: "\(dashboard.dailyCheckIns)", icon: "checklist")
            overviewStatPill(value: "\(dashboard.activeStreak)d", icon: "flame.fill")
        }
    }

    private func overviewStatPill(value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(backgroundTheme.glowColor)

            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(backgroundTheme.glowColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var dashboardStats: some View {
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

    private func actionCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16) {
            switch size {
            case .minimal:
                HStack(spacing: 8) {
                    minimalIcon("bolt.fill")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actions")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        minimalActionButtons(axis: .horizontal)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text("Quick actions")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(quickActionSubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 0)

                    minimalActionButtons(axis: .horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .standard:
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
    }

    @ViewBuilder
    private func minimalActionButtons(axis: HomeActionButtonAxis) -> some View {
        let content = Group {
            if isPrayerTimingEnabled {
                compactActionButton(icon: "timer", tint: backgroundTheme.glowColor) {
                    isShowingPrayerTimer = true
                }
            }

            compactActionButton(icon: "hands.sparkles", tint: .teal) {
                isShowingQuickPrayer = true
            }

            compactActionButton(icon: "plus.circle.fill", tint: backgroundTheme.glowColor) {
                isShowingAddView = true
            }
        }

        switch axis {
        case .horizontal:
            HStack(spacing: 8) {
                content
            }
        case .vertical:
            VStack(spacing: 6) {
                content
            }
        }
    }

    private func compactActionButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14), in: Circle())
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
                        onShowVerses: { item in
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
        }
    }

    private func recentActivityCard(size: HomeScreenCardSize) -> some View {
        let entries = recentEntries(limit: size == .standard ? 3 : 1)

        return AppSurfaceCard(contentPadding: size == .minimal ? 8 : 14) {
            switch size {
            case .minimal:
                HStack(spacing: 8) {
                    minimalIcon(latestActivityIcon)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recent")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(latestActivityTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(latestActivityDetail)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: latestActivityIcon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(backgroundTheme.glowColor)

                        Text("Recent activity")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 0)

                    Text(latestActivityTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(latestActivityDetail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .standard:
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
                                RecentActivityRow(entry: entry, showsPrayerTiming: isPrayerTimingEnabled)

                                if entry.id != entries.last?.id {
                                    Divider()
                                        .padding(.leading, 46)
                                }
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

    private var latestActivityTitle: String {
        recentEntries.first?.kind.title ?? "No logs"
    }

    private var latestActivityDetail: String {
        guard let latest = recentEntries.first else {
            return "Add one"
        }

        return latest.sinTitle ?? latest.sectionTitle
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

private struct HomeScreenGridWidthUnitsKey: LayoutValueKey {
    nonisolated static let defaultValue = 4
}

private struct HomeScreenGridHeightUnitsKey: LayoutValueKey {
    nonisolated static let defaultValue = 2
}

private struct HomeScreenGridUsesFixedHeightKey: LayoutValueKey {
    nonisolated static let defaultValue = true
}

private struct HomeScreenGridLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = gridRows(for: subviews)
        let rowHeights = rows.map { rowHeight(for: $0, subviews: subviews, totalWidth: width) }
        let totalHeight = rowHeights.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * verticalSpacing

        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = gridRows(for: subviews)
        var y = bounds.minY

        for row in rows {
            let rowHeight = rowHeight(for: row, subviews: subviews, totalWidth: bounds.width)
            var x = bounds.minX

            for index in row {
                let width = itemWidth(for: subviews[index][HomeScreenGridWidthUnitsKey.self], totalWidth: bounds.width)
                let itemHeight = subviews[index][HomeScreenGridUsesFixedHeightKey.self]
                    ? fixedHeight(for: subviews[index][HomeScreenGridHeightUnitsKey.self], totalWidth: bounds.width)
                    : rowHeight

                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: width, height: itemHeight)
                )

                x += width + horizontalSpacing
            }

            y += rowHeight + verticalSpacing
        }
    }

    private func gridRows(for subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = []
        var currentRow: [Int] = []
        var currentWidth = 0

        for index in subviews.indices {
            let widthUnits = min(max(subviews[index][HomeScreenGridWidthUnitsKey.self], 1), 4)

            if currentWidth + widthUnits > 4, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentWidth = 0
            }

            currentRow.append(index)
            currentWidth += widthUnits

            if currentWidth == 4 {
                rows.append(currentRow)
                currentRow = []
                currentWidth = 0
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private func rowHeight(for row: [Int], subviews: Subviews, totalWidth: CGFloat) -> CGFloat {
        row.map { index in
            let width = itemWidth(for: subviews[index][HomeScreenGridWidthUnitsKey.self], totalWidth: totalWidth)

            if subviews[index][HomeScreenGridUsesFixedHeightKey.self] {
                return fixedHeight(for: subviews[index][HomeScreenGridHeightUnitsKey.self], totalWidth: totalWidth)
            }

            return subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }.max() ?? fixedHeight(for: 2, totalWidth: totalWidth)
    }

    private func fixedHeight(for heightUnits: Int, totalWidth: CGFloat) -> CGFloat {
        let clampedUnits = min(max(heightUnits, 1), 2)
        let columnWidth = (totalWidth - horizontalSpacing * 3) / 4
        return columnWidth * CGFloat(clampedUnits) + horizontalSpacing * CGFloat(clampedUnits - 1)
    }

    private func itemWidth(for widthUnits: Int, totalWidth: CGFloat) -> CGFloat {
        let clampedUnits = min(max(widthUnits, 1), 4)
        let columnWidth = (totalWidth - horizontalSpacing * 3) / 4
        return columnWidth * CGFloat(clampedUnits) + horizontalSpacing * CGFloat(clampedUnits - 1)
    }
}

private enum HomeActionButtonAxis {
    case horizontal
    case vertical
}

private extension HomeScreenCardSize {
    var widthUnits: Int {
        switch self {
        case .minimal:
            return 2
        case .compact:
            return 2
        case .standard:
            return 4
        }
    }

    var heightUnits: Int {
        switch self {
        case .minimal:
            return 1
        case .compact, .standard:
            return 2
        }
    }
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

    static let compactWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}

#Playground {
    print()
}
