import SwiftUI
import Playgrounds
import UniformTypeIdentifiers

struct HeadwayView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @State private var isShowingAddView = false
    @State private var isShowingQuickPrayer = false
    @State private var isShowingPrayerTimer = false
    @State private var isCustomizingHome = false
    @State private var homeGridWidth: CGFloat = 0
    @State private var draggingHomeCardID: HomeScreenCardID?
    @State private var selectedDefenseItem: SinCategory?
    @AppStorage(HomeScreenLayout.storageKey) private var homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
    @AppStorage("compactSinRows") private var compactSinRows = false
    @AppStorage("isPrayerTimingEnabled") private var isPrayerTimingEnabled = true
    @AppStorage("prayerTimerCountingMode") private var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue

    public var isDaytime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<17:
            return true
        default:
            return false
        }
    }
    
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
                                .layoutValue(key: HomeScreenGridUsesFixedHeightKey.self, value: configuration.id.supportsResizing)
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
                    Button {
                        isShowingAddView.toggle()
                    } label: {
                        Label("Add Log", systemImage: "plus.circle.fill")
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

    private func editableHomeCard(for configuration: HomeScreenCardConfiguration) -> some View {
        ZStack(alignment: .topLeading) {
            homeCard(for: configuration)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!isCustomizingHome)

            if isCustomizingHome {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .onDrag {
                            draggingHomeCardID = configuration.id
                            return NSItemProvider(object: configuration.id.rawValue as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: HomeCardDropDelegate(
                                targetID: configuration.id,
                                targetSize: proxy.size,
                                draggingID: $draggingHomeCardID
                            ) { sourceID, destinationID, insertAfter in
                                moveHomeCard(sourceID, relativeTo: destinationID, insertAfter: insertAfter)
                            }
                        )
                }

                homeCardEditOverlay(for: configuration)
            }
        }
        .contentShape(Rectangle())
        .onDrag {
            guard isCustomizingHome else {
                return NSItemProvider()
            }

            draggingHomeCardID = configuration.id
            return NSItemProvider(object: configuration.id.rawValue as NSString)
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

                VStack(spacing: 8) {
                    ForEach(homeScreenLayout.availableCards) { cardID in
                        Button {
                            addHomeCard(cardID)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: cardID.systemImage)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(backgroundTheme.glowColor)
                                    .frame(width: 36, height: 36)
                                    .background(backgroundTheme.glowColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cardID.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Text(cardID.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.78)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "plus.circle.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(backgroundTheme.glowColor)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.primary.opacity(0.07))
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
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

    private var addWidgetToolbarMenu: some View {
        Menu {
            if homeScreenLayout.availableCards.isEmpty {
                Text("No widgets available")
            } else {
                ForEach(homeScreenLayout.availableCards) { cardID in
                    Button {
                        addHomeCard(cardID)
                    } label: {
                        Label(cardID.title, systemImage: cardID.systemImage)
                    }
                }
            }
        } label: {
            Label("Add Widget", systemImage: "widget.small.badge.plus")
        }
    }

    private func updateHomeLayout(_ update: (inout HomeScreenLayout) -> Void) {
        var layout = homeScreenLayout
        update(&layout)
        homeScreenLayoutData = layout.normalized().encoded()
    }

    private func addHomeCard(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            layout.cards.insert(HomeScreenCardConfiguration(id: id, size: id.supportsResizing ? .compact : .standard), at: 0)
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

    private func moveHomeCard(_ sourceID: HomeScreenCardID, relativeTo destinationID: HomeScreenCardID, insertAfter: Bool) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == sourceID }),
                  let destinationIndex = layout.cards.firstIndex(where: { $0.id == destinationID }) else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            let adjustedDestinationIndex: Int

            if insertAfter {
                adjustedDestinationIndex = sourceIndex < destinationIndex ? destinationIndex : destinationIndex + 1
            } else {
                adjustedDestinationIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
            }

            layout.cards.insert(card, at: adjustedDestinationIndex)
        }
    }

    private func moveHomeCard(_ sourceID: HomeScreenCardID, toGridLocation location: CGPoint) {
        if let target = dropTarget(at: location, excluding: sourceID) {
            moveHomeCard(sourceID, relativeTo: target.id, insertAfter: target.insertAfter)
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

    private func dropTarget(at location: CGPoint, excluding sourceID: HomeScreenCardID) -> (id: HomeScreenCardID, insertAfter: Bool)? {
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
                let insertAfter = location.y > rect.midY || location.x > rect.midX
                return (cards[placement.index].id, insertAfter)
            }
        }

        return placements.first { placement in
            let centerY = CGFloat(placement.y) * (rowHeight + HomeScreenGridLayout.defaultVerticalSpacing) + rowHeight * CGFloat(placement.height) / 2
            let centerX = CGFloat(placement.x) * (columnWidth + HomeScreenGridLayout.defaultHorizontalSpacing) + columnWidth * CGFloat(placement.width) / 2
            return location.y < centerY || (abs(location.y - centerY) < rowHeight / 2 && location.x < centerX)
        }.map { (cards[$0.index].id, false) }
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
                ZStack(alignment: .topLeading) {
                    minimalIcon("sun.max.fill", size: 20)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(greeting)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.56)

                        Text(progressSubtitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .padding(.leading, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func overviewCard(size: HomeScreenCardSize) -> some View {
        AppSurfaceCard(contentPadding: size == .minimal ? 8 : 16) {
            switch size {
            case .minimal:
                ZStack(alignment: .topLeading) {
                    minimalIcon("chart.line.uptrend.xyaxis", size: 20)

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
                    .padding(.leading, 24)
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
                HStack(alignment: .center, spacing: 14) {
                    progressRing(size: size)

                    VStack(alignment: .leading, spacing: 6) {
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

    private var overviewStackedStats: some View {
        VStack(spacing: 0) {
            if isPrayerTimingEnabled {
                overviewStackedStat(title: "Prayer minutes", value: "\(dashboard.prayerMinutes)m", icon: "hands.sparkles")

                Divider()
                    .padding(.leading, 36)
            }

            overviewStackedStat(title: "Check-ins", value: "\(dashboard.dailyCheckIns)", icon: "checklist")

            Divider()
                .padding(.leading, 36)

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
                ZStack(alignment: .topLeading) {
                    minimalIcon("bolt.fill", size: 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actions")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        minimalActionButtons(axis: .horizontal, size: 26, spacing: 6)
                    }
                    .padding(.leading, 24)
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

                            compactActionRowButton(title: "Prayer", icon: "hands.sparkles", tint: .teal, minHeight: 46) {
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
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func minimalActionButtons(axis: HomeActionButtonAxis, size: CGFloat = 24, spacing: CGFloat = 8) -> some View {
        let content = Group {
            if isPrayerTimingEnabled {
                compactActionButton(icon: "timer", tint: backgroundTheme.glowColor, size: size) {
                    isShowingPrayerTimer = true
                }
            }

            compactActionButton(icon: "hands.sparkles", tint: .teal, size: size) {
                isShowingQuickPrayer = true
            }

            compactActionButton(icon: "plus.circle.fill", tint: backgroundTheme.glowColor, size: size) {
                isShowingAddView = true
            }
        }

        switch axis {
        case .horizontal:
            HStack(spacing: spacing) {
                content
            }
        case .vertical:
            VStack(spacing: spacing) {
                content
            }
        }
    }

    private func compactActionButton(icon: String, tint: Color, size: CGFloat = 24, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(tint.opacity(0.14), in: Circle())
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
        let entries = recentEntries(limit: size == .minimal ? 1 : 2)

        return AppSurfaceCard(contentPadding: size == .minimal ? 8 : 14) {
            switch size {
            case .minimal:
                ZStack(alignment: .topLeading) {
                    minimalIcon(latestActivityIcon, size: 20)

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
                    .padding(.leading, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .compact:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: latestActivityIcon)
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
                                RecentActivityRow(entry: entry, showsPrayerTiming: isPrayerTimingEnabled)

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

private struct HomeCardDropDelegate: DropDelegate {
    let targetID: HomeScreenCardID
    let targetSize: CGSize
    @Binding var draggingID: HomeScreenCardID?
    let move: (HomeScreenCardID, HomeScreenCardID, Bool) -> Void

    func dropEntered(info: DropInfo) {
        guard let sourceID = draggingID, sourceID != targetID else {
            return
        }

        let insertAfter = info.location.y > targetSize.height / 2 || info.location.x > targetSize.width / 2
        move(sourceID, targetID, insertAfter)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
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
    static let defaultVerticalSpacing: CGFloat = 8

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
