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
    @State private var homeGridWidth: CGFloat = 0
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
                    HomeScreenGridLayout(horizontalSpacing: HomeScreenGridLayout.defaultHorizontalSpacing, verticalSpacing: HomeScreenGridLayout.defaultVerticalSpacing) {
                        ForEach(homeScreenLayout.cards) { configuration in
                            editableHomeCard(for: configuration)
                                .layoutValue(key: HomeScreenGridWidthUnitsKey.self, value: configuration.id.supportsResizing ? configuration.size.widthUnits : 4)
                                .layoutValue(key: HomeScreenGridHeightUnitsKey.self, value: configuration.id.supportsResizing ? configuration.size.heightUnits : 2)
                                .layoutValue(key: HomeScreenGridUsesFixedHeightKey.self, value: configuration.id.supportsResizing && configuration.size != .standard)
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
        .contentShape(Rectangle())
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

    private func moveHomeCard(_ sourceID: HomeScreenCardID, toGridLocation location: CGPoint) {
        if let targetID = dropTargetID(at: location, excluding: sourceID) {
            moveHomeCard(sourceID, before: targetID)
        } else {
            moveHomeCardToEnd(sourceID)
        }
    }

    private func moveHomeCardToEnd(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == id }),
                  sourceIndex != layout.cards.count - 1 else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            layout.cards.append(card)
        }
    }

    private func dropTargetID(at location: CGPoint, excluding sourceID: HomeScreenCardID) -> HomeScreenCardID? {
        guard homeGridWidth > 0 else { return nil }

        let cards = homeScreenLayout.cards.filter { $0.id != sourceID }
        let placements = HomeScreenGridLayout.gridPlacements(for: cards)
        let columnWidth = max(0, (homeGridWidth - HomeScreenGridLayout.defaultHorizontalSpacing * 3) / 4)
        let rowHeight = columnWidth

        for placement in placements {
            let rect = CGRect(
                x: CGFloat(placement.x) * (columnWidth + HomeScreenGridLayout.defaultHorizontalSpacing),
                y: CGFloat(placement.y) * (rowHeight + HomeScreenGridLayout.defaultVerticalSpacing),
                width: columnWidth * CGFloat(placement.width) + HomeScreenGridLayout.defaultHorizontalSpacing * CGFloat(placement.width - 1),
                height: rowHeight * CGFloat(placement.height) + HomeScreenGridLayout.defaultVerticalSpacing * CGFloat(placement.height - 1)
            )

            if rect.contains(location) {
                return cards[placement.index].id
            }
        }

        return placements.first { placement in
            let centerY = CGFloat(placement.y) * (rowHeight + HomeScreenGridLayout.defaultVerticalSpacing) + rowHeight * CGFloat(placement.height) / 2
            let centerX = CGFloat(placement.x) * (columnWidth + HomeScreenGridLayout.defaultHorizontalSpacing) + columnWidth * CGFloat(placement.width) / 2
            return location.y < centerY || (abs(location.y - centerY) < rowHeight / 2 && location.x < centerX)
        }.map { cards[$0.index].id }
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(greetingSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.78)
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

private struct HomeScreenGridPlacement {
    let index: Int
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

private struct HomeScreenGridLayout: Layout {
    static let defaultHorizontalSpacing: CGFloat = 8
    static let defaultVerticalSpacing: CGFloat = 4

    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let placements = resolvedPlacements(for: subviews, totalWidth: width)
        let totalHeight = placements.map { $0.frame.maxY }.max() ?? 0

        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placements = resolvedPlacements(for: subviews, totalWidth: bounds.width)

        for placement in placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.frame.minX, y: bounds.minY + placement.frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: placement.frame.width, height: placement.frame.height)
            )
        }
    }

    static func gridPlacements(for cards: [HomeScreenCardConfiguration]) -> [HomeScreenGridPlacement] {
        placeItems(cards.indices.map { index in
            let card = cards[index]
            return (
                index: index,
                width: card.id.supportsResizing ? card.size.widthUnits : 4,
                height: card.id.supportsResizing ? card.size.heightUnits : 2
            )
        })
    }

    private func resolvedPlacements(for subviews: Subviews, totalWidth: CGFloat) -> [(index: Int, frame: CGRect)] {
        var occupied = Array(repeating: Array(repeating: false, count: 4), count: max(1, subviews.count * 2))
        var placements: [(index: Int, frame: CGRect)] = []
        var blockYOffset: CGFloat = 0

        for index in subviews.indices {
            let widthUnits = min(max(subviews[index][HomeScreenGridWidthUnitsKey.self], 1), 4)
            let width = length(for: widthUnits, totalWidth: totalWidth, spacing: horizontalSpacing)

            if subviews[index][HomeScreenGridUsesFixedHeightKey.self] {
                let heightUnits = max(subviews[index][HomeScreenGridHeightUnitsKey.self], 1)
                let origin = Self.firstAvailableOrigin(width: widthUnits, height: heightUnits, occupied: &occupied)
                Self.markOccupied(origin: origin, width: widthUnits, height: heightUnits, occupied: &occupied)

                placements.append((
                    index: index,
                    frame: CGRect(
                        x: offset(for: origin.x, totalWidth: totalWidth, spacing: horizontalSpacing),
                        y: blockYOffset + offset(for: origin.y, totalWidth: totalWidth, spacing: verticalSpacing),
                        width: width,
                        height: length(for: heightUnits, totalWidth: totalWidth, spacing: verticalSpacing)
                    )
                ))
            } else {
                let occupiedRows = occupied.lastIndex { row in row.contains(true) }.map { $0 + 1 } ?? 0
                let y = blockYOffset + length(for: occupiedRows, totalWidth: totalWidth, spacing: verticalSpacing) + (occupiedRows > 0 ? verticalSpacing : 0)
                let height = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
                placements.append((index: index, frame: CGRect(x: 0, y: y, width: width, height: height)))

                blockYOffset = y + height + verticalSpacing
                occupied = Array(repeating: Array(repeating: false, count: 4), count: max(1, subviews.count * 2))
            }
        }

        return placements
    }

    private func gridPlacements(for subviews: Subviews, totalWidth: CGFloat) -> [HomeScreenGridPlacement] {
        Self.placeItems(subviews.indices.map { index in
            let width = subviews[index][HomeScreenGridWidthUnitsKey.self]
            return (
                index: index,
                width: width,
                height: heightUnits(for: index, widthUnits: width, subviews: subviews, totalWidth: totalWidth)
            )
        })
    }

    private func heightUnits(for index: Int, widthUnits: Int, subviews: Subviews, totalWidth: CGFloat) -> Int {
        let fixedUnits = max(subviews[index][HomeScreenGridHeightUnitsKey.self], 1)
        guard !subviews[index][HomeScreenGridUsesFixedHeightKey.self] else {
            return fixedUnits
        }

        let width = length(for: widthUnits, totalWidth: totalWidth, spacing: horizontalSpacing)
        let measuredHeight = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        var units = fixedUnits

        while length(for: units, totalWidth: totalWidth, spacing: verticalSpacing) < measuredHeight {
            units += 1
        }

        return units
    }

    private static func placeItems(_ items: [(index: Int, width: Int, height: Int)]) -> [HomeScreenGridPlacement] {
        var occupied = Array(repeating: Array(repeating: false, count: 4), count: max(1, items.count * 2))
        var placements: [HomeScreenGridPlacement] = []

        for item in items {
            let width = min(max(item.width, 1), 4)
            let height = max(item.height, 1)
            let origin = firstAvailableOrigin(width: width, height: height, occupied: &occupied)
            markOccupied(origin: origin, width: width, height: height, occupied: &occupied)
            placements.append(HomeScreenGridPlacement(index: item.index, x: origin.x, y: origin.y, width: width, height: height))
        }

        return placements
    }

    private static func firstAvailableOrigin(width: Int, height: Int, occupied: inout [[Bool]]) -> (x: Int, y: Int) {
        var y = 0

        while true {
            ensureRows(upTo: y + height, occupied: &occupied)

            for x in 0...(4 - width) {
                if isAvailable(x: x, y: y, width: width, height: height, occupied: occupied) {
                    return (x, y)
                }
            }

            y += 1
        }

        return (0, y)
    }

    private static func isAvailable(x: Int, y: Int, width: Int, height: Int, occupied: [[Bool]]) -> Bool {
        for row in y..<(y + height) {
            for column in x..<(x + width) where occupied[row][column] {
                return false
            }
        }

        return true
    }

    private static func markOccupied(origin: (x: Int, y: Int), width: Int, height: Int, occupied: inout [[Bool]]) {
        ensureRows(upTo: origin.y + height, occupied: &occupied)

        for row in origin.y..<(origin.y + height) {
            for column in origin.x..<(origin.x + width) {
                occupied[row][column] = true
            }
        }
    }

    private static func ensureRows(upTo rowCount: Int, occupied: inout [[Bool]]) {
        while occupied.count < rowCount {
            occupied.append(Array(repeating: false, count: 4))
        }
    }

    private func length(for units: Int, totalWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let clampedUnits = max(units, 0)
        guard clampedUnits > 0 else { return 0 }

        let columnWidth = max(0, (totalWidth - horizontalSpacing * 3) / 4)
        return columnWidth * CGFloat(clampedUnits) + spacing * CGFloat(clampedUnits - 1)
    }

    private func offset(for units: Int, totalWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        guard units > 0 else { return 0 }

        let columnWidth = max(0, (totalWidth - horizontalSpacing * 3) / 4)
        return (columnWidth + spacing) * CGFloat(units)
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
