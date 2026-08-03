import SwiftUI

struct SettingsView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @Binding var purityCalculationDate: Date
    let onShowWelcome: () -> Void
    let onDeleteAllData: () -> Void
    let onSaveEntry: (LogEntry) -> Void

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                NavigationLink {
                    AppearanceSettingsPage(backgroundTheme: $backgroundTheme)
                } label: {
                    SettingsLinkRow(
                        title: "Appearance",
                        subtitle: "Themes and background tone",
                        systemImage: "paintbrush"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    HomeSettingsPage(backgroundTheme: $backgroundTheme)
                } label: {
                    SettingsLinkRow(
                        title: "Home",
                        subtitle: "Feed density and activity cards",
                        systemImage: "house.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    TimelineSettingsPage(backgroundTheme: $backgroundTheme)
                } label: {
                    SettingsLinkRow(
                        title: "Timeline",
                        subtitle: "History range and log visibility",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    PuritySettingsPage(
                        backgroundTheme: $backgroundTheme,
                        dashboard: $dashboard,
                        logEntries: logEntries,
                        purityCalculationDate: purityCalculationDate
                    )
                } label: {
                    SettingsLinkRow(
                        title: "Purity",
                        subtitle: "Strictness and clean-time standard",
                        systemImage: "chart.bar.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    PrayerSettingsPage(
                        backgroundTheme: $backgroundTheme,
                        onSaveEntry: onSaveEntry
                    )
                } label: {
                    SettingsLinkRow(
                        title: "Prayer",
                        subtitle: "Quiet mode and timer behavior",
                        systemImage: "hands.sparkles"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    ScriptureSettingsPage(backgroundTheme: $backgroundTheme)
                } label: {
                    SettingsLinkRow(
                        title: "Scripture",
                        subtitle: "Defense verses and explanations",
                        systemImage: "book.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    WeatherSettingsPage(backgroundTheme: $backgroundTheme)
                } label: {
                    SettingsLinkRow(
                        title: "Weather",
                        subtitle: "Local conditions for greetings",
                        systemImage: "cloud.sun.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    AboutSettingsPage(
                        backgroundTheme: $backgroundTheme,
                        onShowWelcome: onShowWelcome,
                        onDeleteAllData: onDeleteAllData
                    )
                } label: {
                    SettingsLinkRow(
                        title: "About",
                        subtitle: "App version and notes",
                        systemImage: "info.circle.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

                NavigationLink {
                    DeveloperSettingsPage(
                        backgroundTheme: $backgroundTheme,
                        dashboard: $dashboard,
                        logEntries: $logEntries,
                        purityCalculationDate: $purityCalculationDate
                    )
                } label: {
                    SettingsLinkRow(
                        title: "Developer",
                        subtitle: "Test data, modes, and purity scenarios",
                        systemImage: "hammer.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let subtitle: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemFill))

                Image(systemName: systemImage ?? "info.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

private struct AppearanceSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Theme"), footer: Text("The theme changes the background while the interface stays consistent. Choose a theme that matches your style.")) {
                    ForEach(AppBackgroundTheme.allCases) { theme in
                        Button {
                            backgroundTheme = theme
                        } label: {
                            ThemeRow(theme: theme, isSelected: backgroundTheme == theme)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct HomeSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Layout")) {
                    Toggle("Show recent activity", isOn: $preferences.showRecentActivity)
                    Toggle("Compact sin list", isOn: $preferences.compactSinRows)

                    Button(role: .destructive) {
                        preferences.homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
                        preferences.showRecentActivity = true
                        preferences.compactSinRows = false
                    } label: {
                        Label("Reset Home Screen", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct TimelineSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences

    private var timelineRangeBinding: Binding<TimelineRange> {
        Binding {
            preferences.timelineRange
        } set: { newValue in
            preferences.timelineRange = newValue
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("History"), footer: Text("Choose how far back the Timeline tab should show logs. Older logs stay saved and return when you choose a longer range.")) {
                    Picker("Show logs from", selection: timelineRangeBinding) {
                        ForEach(TimelineRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct PuritySettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Environment(AppPreferenceStore.self) private var preferences
    let logEntries: [LogEntry]
    let purityCalculationDate: Date

    private var selectedStrictness: PurityStrictness {
        preferences.purityStrictness
    }

    private var strictnessBinding: Binding<PurityStrictness> {
        Binding {
            selectedStrictness
        } set: { newValue in
            preferences.purityStrictness = newValue
            dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate, strictness: newValue)
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Strictness")) {
                    Picker("Purity strictness", selection: strictnessBinding) {
                        ForEach(PurityStrictness.allCases) { strictness in
                            Text(strictness.title).tag(strictness)
                        }
                    }
                }

                Section(header: Text("Current Standard")) {
                    HStack {
                        Text("History range")
                        Spacer()
                        Text("\(selectedStrictness.historyDays) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Pure after")
                        Spacer()
                        Text("\(selectedStrictness.pureAfterDays) clean days")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Purity")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct PrayerSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    let onSaveEntry: (LogEntry) -> Void
    @State private var isShowingPrayerTimer = false

    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        preferences.prayerTimerCountingMode
    }

    private var prayerTimerCountingModeBinding: Binding<PrayerTimerCountingMode> {
        Binding {
            preferences.prayerTimerCountingMode
        } set: { newValue in
            preferences.prayerTimerCountingMode = newValue
        }
    }

    var body: some View {
        @Bindable var preferences = preferences
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Timing"), footer: preferences.isPrayerTimingEnabled ? Text("The prayer timer is enabled accros the app. You can track prayer minutes with this feature and see a record of the total time on you dashboard as well as on the timeline.") : Text("The prayer timer is disables accros the app. This means that prayer minutes are not tracked which helps you put the focus truly on God and on God alone.")) {
                    Toggle("Enable prayer timing", isOn: $preferences.isPrayerTimingEnabled)

                    if preferences.isPrayerTimingEnabled {
                        Picker("Timer counting", selection: prayerTimerCountingModeBinding) {
                            ForEach(PrayerTimerCountingMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                    }
                }

                if preferences.isPrayerTimingEnabled {
                    Section(header: Text("Session"), footer: Text("This keeps the screen awake during a prayer session")) {
                        Toggle("Keep screen awake", isOn: $preferences.keepScreenAwakeDuringPrayer)
                    }
                    
                } else {

                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Prayer")
        .navigationBarTitleDisplayMode(.large) 
        .onChange(of: preferences.isPrayerTimingEnabled) { _, isEnabled in
            if !isEnabled {
                isShowingPrayerTimer = false
            }
        }
        .fullScreenCover(isPresented: $isShowingPrayerTimer) {
            PrayerTimerView(backgroundTheme: $backgroundTheme) { entry in
                onSaveEntry(entry)
            }
        }
    }
}

private struct ScriptureSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Verse arsenal"), footer: Text("When you tap on the icon of a sin in the sins list, your verse arsenal shows up. These are verses you note down to use as a counter agains the devil. You can add not only the verse and the bible quote, but also a descriptive note beneath it to, for example, specify what the use is of the verse.")) {
                    Toggle("Enable verse arsenal", isOn: $preferences.enableVerseInventory)
                    if preferences.enableVerseInventory {
                        Toggle("Show verse desctiptions", isOn: $preferences.showVerseApplications)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Scripture")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct WeatherSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    private let openMeteoURL = URL(string: "https://open-meteo.com/")

    var body: some View {
        @Bindable var preferences = preferences
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Welcome Greeting"), footer: Text("When enabled, the welcome widget can request your approximate location and use current weather to adjust its greeting. Time of day and recent logs still shape the greeting either way.")) {
                    Toggle("Use local weather", isOn: $preferences.isGreetingWeatherEnabled)
                }

                Section(header: Text("Location"), footer: Text("Location permission is controlled by iOS. If permission is denied, the app keeps using time of day and recent logs without weather.")) {
                    HStack {
                        Label("Approximate location", systemImage: "location.fill")
                        Spacer()
                        Text(preferences.isGreetingWeatherEnabled ? "On request" : "Off")
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Sensitivity"), footer: Text("Adjust when current conditions should count as warm, cold, or breezy in the welcome greeting.")) {
                    WeatherThresholdSlider(
                        title: "Warm at",
                        value: $preferences.greetingWeatherWarmThresholdCelsius,
                        range: 18...38,
                        unit: "C"
                    )

                    WeatherThresholdSlider(
                        title: "Cold at",
                        value: $preferences.greetingWeatherColdThresholdCelsius,
                        range: -10...12,
                        unit: "C"
                    )

                    WeatherThresholdSlider(
                        title: "Breezy at",
                        value: $preferences.greetingWeatherBreezyThresholdKilometersPerHour,
                        range: 10...50,
                        unit: "km/h"
                    )

                    Button {
                        resetThresholds()
                    } label: {
                        Label("Reset Weather Sensitivity", systemImage: "arrow.counterclockwise")
                    }
                }
                .disabled(!preferences.isGreetingWeatherEnabled)

                Section(header: Text("Provider"), footer: Text("Weather data is used only to tune the greeting text and icon.")) {
                    if let openMeteoURL {
                        Link(destination: openMeteoURL) {
                            Label("Weather data by Open-Meteo", systemImage: "cloud.sun.fill")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.large)
    }

    private func resetThresholds() {
        preferences.greetingWeatherWarmThresholdCelsius = GreetingWeatherThresholds.defaultWarmThresholdCelsius
        preferences.greetingWeatherColdThresholdCelsius = GreetingWeatherThresholds.defaultColdThresholdCelsius
        preferences.greetingWeatherBreezyThresholdKilometersPerHour = GreetingWeatherThresholds.defaultBreezyThresholdKilometersPerHour
    }
}

private struct WeatherThresholdSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    private var valueText: String {
        "\(Int(value.rounded())) \(unit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: 1)
        }
        .padding(.vertical, 4)
    }
}

private struct AboutSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Environment(AppPreferenceStore.self) private var preferences
    let onShowWelcome: () -> Void
    let onDeleteAllData: () -> Void
    @State private var iCloudStatus = ICloudAccountStatusViewModel()
    @State private var hasChangedICloudSyncMode = false
    @State private var isShowingDeleteAllDataConfirmation = false
    private let openMeteoURL = URL(string: "https://open-meteo.com/")

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func iCloudFooterText(hasChangedSyncMode: Bool) -> Text {
        if AppPersistence.isICloudSyncArchived {
            return Text("iCloud sync is archived in the codebase but disabled for this build so the app can run on a personal development profile. Local saving stays on.")
        }

        if hasChangedSyncMode {
            return Text("Sync mode changes apply the next time you open the app. Existing local data will be kept and uploaded when iCloud sync starts.")
        }

        return Text("iCloud sync is optional. Local saving stays on either way.")
    }

    private var iCloudSyncBinding: Binding<Bool> {
        Binding {
            AppPersistence.isICloudSyncArchived ? false : preferences.isICloudSyncEnabled
        } set: { isOn in
            guard !AppPersistence.isICloudSyncArchived else { return }
            preferences.isICloudSyncEnabled = isOn
        }
    }


    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(versionText)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        onShowWelcome()
                    } label: {
                        Text("Show Onboarding")
                    }
                    
                }

                Section(header: Text("iCloud"), footer: iCloudFooterText(hasChangedSyncMode: hasChangedICloudSyncMode)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(iCloudStatus.status.title, systemImage: iCloudStatus.status.canEnableSync ? "icloud.fill" : "icloud.slash")
                            .font(.body.weight(.semibold))

                        Text(iCloudStatus.status.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)

                    Toggle("iCloud Sync", isOn: iCloudSyncBinding)
                        .disabled(AppPersistence.isICloudSyncArchived || !iCloudStatus.status.canEnableSync)
                        .onChange(of: preferences.isICloudSyncEnabled) { _, _ in
                            hasChangedICloudSyncMode = true
                        }
                }

                Section(header: Text("Data"), footer: Text("This removes local logs, preferences, custom verses, and iCloud sync settings from this device. If iCloud sync is enabled, deletions can sync to iCloud on the next sync pass.")) {
                    Button(role: .destructive) {
                        isShowingDeleteAllDataConfirmation = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash.fill")
                    }
                }

                Section(header: Text("Weather"), footer: Text("Weather helps tailor the welcome greeting. Location is used only for current local conditions.")) {
                    if let openMeteoURL {
                        Link(destination: openMeteoURL) {
                            Label("Weather data by Open-Meteo", systemImage: "cloud.sun.fill")
                        }
                    }
                }
                
                Section("Help") {
                    Button {
                        //Add logic to show a list of hidden tips and tricks
                    } label: {
                        Text("Tips and Tricks")
                            .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete all data?", isPresented: $isShowingDeleteAllDataConfirmation) {
            Button("Delete All Data", role: .destructive) {
                onDeleteAllData()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes your logs, settings, custom verses, and sync preference from this device.")
        }
        .task {
            guard !AppPersistence.isICloudSyncArchived else { return }
            await iCloudStatus.refresh()
        }
        .task {
            guard !AppPersistence.isICloudSyncArchived else { return }
            await iCloudStatus.monitorAccountChanges()
        }
    }
}

private struct DeveloperSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @Binding var purityCalculationDate: Date
    @Environment(AppPreferenceStore.self) private var preferences
    @State private var selectedSectionIndex = 0
    @State private var selectedItemIndex = 0

    private var selectedStrictness: PurityStrictness {
        preferences.purityStrictness
    }

    private var scenarios: [DeveloperPurityScenario] {
        let historyDays = selectedStrictness.historyDays
        let weeklyLossCount = max(1, Int((Double(historyDays) / 7).rounded()))
        let oftenLossCount = max(weeklyLossCount + 1, Int((Double(historyDays) * 2.2 / 7).rounded()))
        let dailyLossCount = max(oftenLossCount + 1, Int((Double(historyDays) * 3.8 / 7).rounded()))
        let rockBottomLossCount = max(dailyLossCount + 1, Int((Double(historyDays) * 5.5 / 7).rounded()))

        return [
            .init(title: "Rock bottom", detail: "Very high loss rate in \(historyDays)d", lossDayOffsets: dayOffsets(count: rockBottomLossCount, within: historyDays)),
            .init(title: "Daily", detail: "Daily-level loss rate in \(historyDays)d", lossDayOffsets: dayOffsets(count: dailyLossCount, within: historyDays)),
            .init(title: "Often", detail: "Several weekly losses in \(historyDays)d", lossDayOffsets: dayOffsets(count: oftenLossCount, within: historyDays)),
            .init(title: "Weekly", detail: "About weekly in \(historyDays)d", lossDayOffsets: dayOffsets(count: weeklyLossCount, within: historyDays)),
            .init(title: "Occasional", detail: "A few monthly equivalents", lossDayOffsets: dayOffsets(count: max(1, weeklyLossCount / 2), within: historyDays)),
            .init(title: "Clean window", detail: "Last loss just outside \(historyDays)d", lossDayOffsets: [historyDays + 1]),
            .init(title: "Pure", detail: "Last loss past \(selectedStrictness.pureAfterDays)d", lossDayOffsets: [selectedStrictness.pureAfterDays + 1]),
            .init(title: "Prayer boost", detail: "Weekly losses plus prayer", lossDayOffsets: dayOffsets(count: weeklyLossCount, within: historyDays), prayerDayOffsets: dayOffsets(count: 6, within: historyDays)),
            .init(title: "Resistance only", detail: "Resistance without purity penalty", lossDayOffsets: [], resistanceDayOffsets: dayOffsets(count: 6, within: historyDays)),
            .init(title: "Mixed history", detail: "Weekly losses plus resistance", lossDayOffsets: dayOffsets(count: weeklyLossCount, within: historyDays), resistanceDayOffsets: dayOffsets(count: 4, within: historyDays))
        ]
    }

    private var selectedSection: SinSection? {
        guard dashboard.sections.indices.contains(selectedSectionIndex) else { return nil }
        return dashboard.sections[selectedSectionIndex]
    }

    private var selectedItem: SinCategory? {
        guard let selectedSection, selectedSection.items.indices.contains(selectedItemIndex) else { return nil }
        return selectedSection.items[selectedItemIndex]
    }

    private var selectedLevelText: String {
        guard let selectedSection, let selectedItem else { return "No sin selected" }
        let snapshot = PurityCalculator.snapshot(
            sectionTitle: selectedSection.title,
            sinTitle: selectedItem.title,
            entries: logEntries,
            now: purityCalculationDate,
            strictness: selectedStrictness,
            qualifiesForPrayerBoost: selectedItem.qualifiesForPrayerPurityBoost
        )
        let cleanText = snapshot.cleanDayCount.map { "Clean \($0)d" } ?? "No history"
        let prayerText = selectedItem.qualifiesForPrayerPurityBoost ? " | Prayer +\(SinFrequencyScale.percentage(for: snapshot.prayerPurityBoost))%" : ""
        return "\(SinFrequencyScale.label(for: selectedItem.progress)) | Losses \(snapshot.recentLossCount) | Resistance \(snapshot.recentResistanceCount) | \(cleanText)\(prayerText)"
    }

    private func dayOffsets(count: Int, within days: Int) -> [Int] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [0] }

        let maxOffset = max(0, days - 1)
        return (0..<count).map { index in
            Int((Double(index) / Double(count - 1) * Double(maxOffset)).rounded())
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Target Sin"), footer: Text(selectedLevelText)) {
                    Picker("Section", selection: $selectedSectionIndex) {
                        ForEach(dashboard.sections.indices, id: \.self) { index in
                            Text(dashboard.sections[index].title).tag(index)
                        }
                    }
                    .onChange(of: selectedSectionIndex) { _, _ in
                        selectedItemIndex = 0
                    }

                    if let selectedSection {
                        Picker("Sin", selection: $selectedItemIndex) {
                            ForEach(selectedSection.items.indices, id: \.self) { index in
                                Text(selectedSection.items[index].title).tag(index)
                            }
                        }
                    }
                }

                Section(header: Text("Purity Scenarios"), footer: Text("Scenarios replace selected-sin logs and developer prayer scenario logs, then recalculate purity from the seeded history.")) {
                    ForEach(scenarios) { scenario in
                        Button {
                            applyScenario(scenario)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scenario.title)
                                        .foregroundStyle(.primary)
                                    Text(scenario.detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section(header: Text("Test Clock"), footer: Text("Jump the calculation date to verify that old losses age into Rare, Clean window, and Pure.")) {
                    HStack {
                        Text("Calculation date")
                        Spacer()
                        Text(Self.dateFormatter.string(from: purityCalculationDate))
                            .foregroundStyle(.secondary)
                    }

                    Button("Advance 1 day") {
                        advanceCalculationDate(by: 1)
                    }

                    Button("Advance 7 days") {
                        advanceCalculationDate(by: 7)
                    }

                    Button("Advance 30 days") {
                        advanceCalculationDate(by: 30)
                    }

                    Button("Reset to today") {
                        purityCalculationDate = Date()
                        recalculatePurity()
                    }
                }

                Section(header: Text("Live Logs"), footer: Text("These buttons create normal timeline entries and update dashboard stats.")) {
                    Button("Log loss now") {
                        addLiveEntry(kind: .loss)
                    }

                    Button("Log resistance now") {
                        addLiveEntry(kind: .victory)
                    }

                    Button("Log quick prayer now") {
                        addLiveEntry(kind: .quickPrayer, prayerMinutes: 1)
                    }
                }

                Section(header: Text("Reset")) {
                    Button(role: .destructive) {
                        clearSelectedSinLogs()
                    } label: {
                        Label("Clear Selected Sin Logs", systemImage: "eraser")
                    }

                    Button(role: .destructive) {
                        logEntries.removeAll()
                        dashboard = DashboardViewModel()
                        purityCalculationDate = Date()
                    } label: {
                        Label("Reset Dashboard Test State", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.large)
    }

    private func applyScenario(_ scenario: DeveloperPurityScenario) {
        guard let selectedSection, let selectedItem else { return }
        removeEntriesForSelectedSin(sectionTitle: selectedSection.title, sinTitle: selectedItem.title)
        removeDeveloperPrayerScenarioEntries()

        let lossEntries = scenario.lossDayOffsets.compactMap { dayOffset in
            scenarioEntry(kind: .loss, dayOffset: dayOffset, sectionTitle: selectedSection.title, sinTitle: selectedItem.title, title: scenario.title)
        }
        let resistanceEntries = scenario.resistanceDayOffsets.compactMap { dayOffset in
            scenarioEntry(kind: .victory, dayOffset: dayOffset, sectionTitle: selectedSection.title, sinTitle: selectedItem.title, title: scenario.title)
        }
        let prayerEntries = scenario.prayerDayOffsets.compactMap { dayOffset in
            scenarioEntry(kind: .quickPrayer, dayOffset: dayOffset, sectionTitle: "Prayer", sinTitle: nil, title: scenario.title)
        }

        let seededEntries = lossEntries + resistanceEntries + prayerEntries
        logEntries.insert(contentsOf: seededEntries.sorted { $0.occurredAt > $1.occurredAt }, at: 0)
        recalculatePurity()
    }

    private func scenarioEntry(kind: LogEntry.Kind, dayOffset: Int, sectionTitle: String, sinTitle: String?, title: String) -> LogEntry? {
        Calendar.current.date(byAdding: .day, value: -dayOffset, to: purityCalculationDate).map { date in
            LogEntry(
                kind: kind,
                sectionTitle: sectionTitle,
                sinTitle: sinTitle,
                note: "Developer scenario: \(title)",
                prayerMinutes: 0,
                occurredAt: date
            )
        }
    }

    private func addLiveEntry(kind: LogEntry.Kind, prayerMinutes: Int = 0) {
        guard let selectedSection, let selectedItem else { return }
        let entry = LogEntry(
            kind: kind,
            sectionTitle: selectedSection.title,
            sinTitle: selectedItem.title,
            note: "Developer test log",
            prayerMinutes: prayerMinutes,
            occurredAt: purityCalculationDate
        )

        logEntries.insert(entry, at: 0)
        dashboard.record(entry)
        recalculatePurity()
    }

    private func advanceCalculationDate(by days: Int) {
        purityCalculationDate = Calendar.current.date(byAdding: .day, value: days, to: purityCalculationDate) ?? purityCalculationDate
        recalculatePurity()
    }

    private func clearSelectedSinLogs() {
        guard let selectedSection, let selectedItem else { return }
        removeEntriesForSelectedSin(sectionTitle: selectedSection.title, sinTitle: selectedItem.title)
        recalculatePurity()
    }

    private func recalculatePurity() {
        dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate, strictness: selectedStrictness)
    }

    private func removeEntriesForSelectedSin(sectionTitle: String, sinTitle: String) {
        logEntries.removeAll { entry in
            entry.sectionTitle == sectionTitle && entry.sinTitle == sinTitle
        }
    }

    private func removeDeveloperPrayerScenarioEntries() {
        logEntries.removeAll { entry in
            (entry.kind == .prayer || entry.kind == .quickPrayer) &&
            entry.sectionTitle == "Prayer" &&
            entry.note.hasPrefix("Developer scenario:")
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

}

private struct DeveloperPurityScenario: Identifiable {
    let title: String
    let detail: String
    let lossDayOffsets: [Int]
    var resistanceDayOffsets: [Int] = []
    var prayerDayOffsets: [Int] = []

    var id: String { title }
}

private struct ThemeRow: View {
    let theme: AppBackgroundTheme
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark ? theme.colors : theme.lightColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(theme.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(theme.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(uiColor: .secondarySystemBackground).opacity(0.22) : Color(uiColor: .secondarySystemBackground))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.10), lineWidth: 1)
        )
    }
}

private struct SettingsNoteRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(uiColor: .secondarySystemFill))
                .frame(width: 8, height: 8)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            backgroundTheme: .constant(.blood),
            dashboard: .constant(DashboardViewModel()),
            logEntries: .constant([]),
            purityCalculationDate: .constant(Date()),
            onShowWelcome: {},
            onDeleteAllData: {},
            onSaveEntry: { _ in }
        )
    }
}
