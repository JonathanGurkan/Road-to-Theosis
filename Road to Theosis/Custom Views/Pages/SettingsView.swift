import SwiftUI

struct SettingsView: View {
    @Binding var backgroundTheme: AppBackgroundTheme
    let onShowWelcome: () -> Void
    let onSaveEntry: (LogEntry) -> Void

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section("Pages") {
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
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemFill))

                Image(systemName: systemImage)
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
                Section("Theme") {
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

                Section("Notes") {
                    SettingsNoteRow(
                        title: "Background only",
                        subtitle: "The theme changes the background while the interface stays consistent."
                    )

                    SettingsNoteRow(
                        title: "Old design restored",
                        subtitle: "The larger swatches and checkmark make the selection easier to scan."
                    )
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
                Section("Layout") {
                    Toggle("Show recent activity", isOn: $showRecentActivity)
                    Toggle("Compact sin list", isOn: $compactSinRows)
                }

                Section("Notes") {
                    SettingsNoteRow(title: "Recent activity", subtitle: "Shows the latest prayer sessions and logs on Home.")
                    SettingsNoteRow(title: "Compact rows", subtitle: "Uses tighter spacing in the sins list.")
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
                Section("Timing") {
                    Toggle("Enable prayer timing", isOn: $isPrayerTimingEnabled)
                }

                if isPrayerTimingEnabled {
                    Section("Session") {
                        Toggle("Keep screen awake", isOn: $keepScreenAwakeDuringPrayer)
                    }

                    Section("Timer") {
                        Button {
                            isShowingPrayerTimer = true
                        } label: {
                            SettingsLinkRow(
                                title: "Start timed prayer",
                                subtitle: "Open the focused prayer timer from here.",
                                systemImage: "timer"
                            )
                        }
                        .buttonStyle(.plain)
                        .tint(backgroundTheme.glowColor)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    }

                    Section("Notes") {
                        SettingsNoteRow(title: "Focused mode", subtitle: "Start the timer, set the phone aside, and pray.")
                        SettingsNoteRow(title: "Saved time", subtitle: "The elapsed minutes are added to the Timeline when you stop.")
                    }
                } else {
                    Section("Notes") {
                        SettingsNoteRow(title: "Prayer first", subtitle: "Timed sessions and manual prayer-minute fields are hidden across the app.")
                    }
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
    @AppStorage("showVerseApplications") private var showVerseApplications = true

    var body: some View {
        ZStack {
            AppBackgroundView(theme: backgroundTheme)

            List {
                Section("Verses") {
                    Toggle("Show verse explanations", isOn: $showVerseApplications)
                }

                Section("Use") {
                    SettingsNoteRow(title: "Tap the icon", subtitle: "A swipeable NKJV verse sheet opens from the tapped item.")
                    SettingsNoteRow(title: "Guidance", subtitle: "You can keep the short application text visible or hide it.")
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
                    SettingsNoteRow(title: "Version", subtitle: versionText)
                    SettingsNoteRow(title: "Timeline", subtitle: "Prayer sessions, victories, losses, and notes stay together.")

                    Button {
                        onShowWelcome()
                    } label: {
                        SettingsLinkRow(
                            title: "Show Welcome",
                            subtitle: "Replay the intro pages anytime.",
                            systemImage: "sparkles"
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }

                Section("Style") {
                    SettingsNoteRow(title: "Foreground", subtitle: "The app keeps grouped spacing and standard hierarchy.")
                    SettingsNoteRow(title: "Background", subtitle: "Themes keep the interface calm while preserving depth.")
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
