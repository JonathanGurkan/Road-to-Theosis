import SwiftUI

struct SettingsView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
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
        HStack(spacing: 14) {
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
    @AppStorage("showRecentActivity") private var showRecentActivity = true
    @AppStorage("compactSinRows") private var compactSinRows = false

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Layout")) {
                    Toggle("Show recent activity", isOn: $showRecentActivity)
                    Toggle("Compact sin list", isOn: $compactSinRows)
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
    @State private var isShowingPrayerTimer = false

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section(header: Text("Timing"), footer: isPrayerTimingEnabled ? Text("The prayer timer is enabled accros the app. You can track prayer minutes with this feature and see a record of the total time on you dashboard as well as on the timeline.") : Text("The prayer timer is disables accros the app. This means that prayer minutes are not tracked which helps you put the focus truly on God and on God alone.")) {
                    Toggle("Enable prayer timing", isOn: $isPrayerTimingEnabled)
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
        SettingsView(backgroundTheme: .constant(.blood), onShowWelcome: {}, onSaveEntry: { _ in })
    }
}
