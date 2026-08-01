import SwiftUI

struct SettingsView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var showVictorySwipeAction: Bool
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @Binding var purityCalculationDate: Date
    let onShowWelcome: () -> Void
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
                    HomeSettingsPage(
                        backgroundTheme: $backgroundTheme,
                        showVictorySwipeAction: $showVictorySwipeAction
                    )
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
                    AboutSettingsPage(
                        backgroundTheme: $backgroundTheme,
                        onShowWelcome: onShowWelcome
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
    @Binding var showVictorySwipeAction: Bool
    @AppStorage(HomeScreenLayout.storageKey) private var homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
    @AppStorage("showRecentActivity") private var showRecentActivity = true
    @AppStorage("compactSinRows") private var compactSinRows = false
    @AppStorage("usesFocusProgressSliders") private var usesFocusProgressSliders = true
    @AppStorage("focusSliderStyle") private var focusSliderStyleRaw = FocusSliderStyle.clean.rawValue

    private var focusSliderStyleBinding: Binding<FocusSliderStyle> {
        Binding {
            FocusSliderStyle(rawValue: focusSliderStyleRaw) ?? .clean
        } set: { newValue in
            focusSliderStyleRaw = newValue.rawValue
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Layout")) {
                    Toggle("Show recent activity", isOn: $showRecentActivity)
                    Toggle("Compact sin list", isOn: $compactSinRows)
                    Toggle("Use frequency sliders", isOn: $usesFocusProgressSliders)
                    Toggle("Show victory swipe action", isOn: $showVictorySwipeAction)

                    if usesFocusProgressSliders {
                        Picker("Slider style", selection: focusSliderStyleBinding) {
                            ForEach(FocusSliderStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }

                        Text((FocusSliderStyle(rawValue: focusSliderStyleRaw) ?? .clean).subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
                        showRecentActivity = true
                        compactSinRows = false
                        usesFocusProgressSliders = true
                        focusSliderStyleRaw = FocusSliderStyle.clean.rawValue
                        showVictorySwipeAction = false
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

private struct PrayerSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let onSaveEntry: (LogEntry) -> Void
    @AppStorage("keepScreenAwakeDuringPrayer") private var keepScreenAwakeDuringPrayer = true
    @AppStorage("isPrayerTimingEnabled") private var isPrayerTimingEnabled = true
    @AppStorage("prayerTimerCountingMode") private var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue
    @State private var isShowingPrayerTimer = false

    private var prayerTimerCountingMode: PrayerTimerCountingMode {
        PrayerTimerCountingMode(rawValue: prayerTimerCountingModeRaw) ?? .foreground
    }

    private var prayerTimerCountingModeBinding: Binding<PrayerTimerCountingMode> {
        Binding {
            prayerTimerCountingMode
        } set: { newValue in
            prayerTimerCountingModeRaw = newValue.rawValue
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Timing"), footer: isPrayerTimingEnabled ? Text("The prayer timer is enabled accros the app. You can track prayer minutes with this feature and see a record of the total time on you dashboard as well as on the timeline.") : Text("The prayer timer is disables accros the app. This means that prayer minutes are not tracked which helps you put the focus truly on God and on God alone.")) {
                    Toggle("Enable prayer timing", isOn: $isPrayerTimingEnabled)

                    if isPrayerTimingEnabled {
                        Picker("Timer counting", selection: prayerTimerCountingModeBinding) {
                            ForEach(PrayerTimerCountingMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                    }
                }

                if isPrayerTimingEnabled {
                    Section(header: Text("Session"), footer: Text("This keeps the screen awake during a prayer session")) {
                        Toggle("Keep screen awake", isOn: $keepScreenAwakeDuringPrayer)
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
        .onChange(of: isPrayerTimingEnabled) { _, isEnabled in
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
    @AppStorage("enableVerseInventory") private var enableVerseInventory = true
    @AppStorage("showVerseApplications") private var showVerseApplications = true

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Verse arsenal"), footer: Text("When you tap on the icon of a sin in the sins list, your verse arsenal shows up. These are verses you note down to use as a counter agains the devil. You can add not only the verse and the bible quote, but also a descriptive note beneath it to, for example, specify what the use is of the verse.")) {
                    Toggle("Enable verse arsenal", isOn: $enableVerseInventory)
                    if enableVerseInventory {
                        Toggle("Show verse desctiptions", isOn: $showVerseApplications)
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

private struct AboutSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let onShowWelcome: () -> Void

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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
    }
}

private struct DeveloperSettingsPage: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    @Binding var dashboard: DashboardViewModel
    @Binding var logEntries: [LogEntry]
    @Binding var purityCalculationDate: Date
    @AppStorage("usesFocusProgressSliders") private var usesFocusProgressSliders = true
    @AppStorage("focusSliderStyle") private var focusSliderStyleRaw = FocusSliderStyle.clean.rawValue
    @State private var selectedSectionIndex = 0
    @State private var selectedItemIndex = 0

    private let scenarios: [DeveloperPurityScenario] = [
        .init(title: "Rock bottom", detail: "24 recent losses", lossDayOffsets: Array(0..<24)),
        .init(title: "Daily", detail: "16 recent losses", lossDayOffsets: Array(0..<16)),
        .init(title: "Often", detail: "10 recent losses", lossDayOffsets: [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]),
        .init(title: "Weekly", detail: "5 recent losses", lossDayOffsets: [0, 6, 12, 18, 24]),
        .init(title: "Occasional", detail: "3 recent losses", lossDayOffsets: [0, 10, 20]),
        .init(title: "Rare", detail: "1 recent loss", lossDayOffsets: [0]),
        .init(title: "Clean window", detail: "last loss 31 days ago", lossDayOffsets: [31]),
        .init(title: "Pure", detail: "last loss 91 days ago", lossDayOffsets: [91])
    ]

    private var selectedSection: SinSection? {
        guard dashboard.sections.indices.contains(selectedSectionIndex) else { return nil }
        return dashboard.sections[selectedSectionIndex]
    }

    private var selectedItem: SinCategory? {
        guard let selectedSection, selectedSection.items.indices.contains(selectedItemIndex) else { return nil }
        return selectedSection.items[selectedItemIndex]
    }

    private var selectedLevelText: String {
        guard let selectedItem else { return "No sin selected" }
        return SinFrequencyScale.label(for: selectedItem.progress)
    }

    private var focusSliderStyleBinding: Binding<FocusSliderStyle> {
        Binding {
            FocusSliderStyle(rawValue: focusSliderStyleRaw) ?? .clean
        } set: { newValue in
            focusSliderStyleRaw = newValue.rawValue
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Display Mode"), footer: Text("Use this to check the exact same sin list in slider mode and bar mode.")) {
                    Toggle("Use frequency sliders", isOn: $usesFocusProgressSliders)

                    if usesFocusProgressSliders {
                        Picker("Slider style", selection: focusSliderStyleBinding) {
                            ForEach(FocusSliderStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                    }
                }

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

                Section(header: Text("Purity Scenarios"), footer: Text("Scenarios replace logs only for the selected sin, then recalculate purity from the seeded history.")) {
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
                        dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate)
                    }
                }

                Section(header: Text("Live Logs"), footer: Text("These buttons create normal timeline entries and update dashboard stats.")) {
                    Button("Log loss now") {
                        addLiveEntry(kind: .loss)
                    }

                    Button("Log victory now") {
                        addLiveEntry(kind: .victory)
                    }

                    Button("Log quick prayer now") {
                        addLiveEntry(kind: .quickPrayer, prayerMinutes: 1)
                    }
                }

                Section(header: Text("Reset")) {
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

        let seededEntries = scenario.lossDayOffsets.compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: -dayOffset, to: purityCalculationDate).map { date in
                LogEntry(
                    kind: .loss,
                    sectionTitle: selectedSection.title,
                    sinTitle: selectedItem.title,
                    note: "Developer scenario: \(scenario.title)",
                    prayerMinutes: 0,
                    occurredAt: date
                )
            }
        }

        logEntries.insert(contentsOf: seededEntries.sorted { $0.occurredAt > $1.occurredAt }, at: 0)
        dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate)
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
        dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate)
    }

    private func advanceCalculationDate(by days: Int) {
        purityCalculationDate = Calendar.current.date(byAdding: .day, value: days, to: purityCalculationDate) ?? purityCalculationDate
        dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate)
    }

    private func removeEntriesForSelectedSin(sectionTitle: String, sinTitle: String) {
        logEntries.removeAll { entry in
            entry.sectionTitle == sectionTitle && entry.sinTitle == sinTitle
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
            showVictorySwipeAction: .constant(false),
            dashboard: .constant(DashboardViewModel()),
            logEntries: .constant([]),
            purityCalculationDate: .constant(Date()),
            onShowWelcome: {},
            onSaveEntry: { _ in }
        )
    }
}
