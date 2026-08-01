import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool
    let onFinish: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var pageIndex: Int = 0
    @State private var pageProgress: Double = 0
    private let autoAdvanceDuration: Double = 7

    private let pages: [WelcomePage] = [
        .init(
            title: "Welcome to Road to Theosis",
            subtitle: "A focused place to log sin, prayer, and growth without noise, while keeping the whole journey easy to review later.",
            icon: "cross.fill",
            tint: .red,
            points: [
                "Track exact sins instead of only broad categories.",
                "Log quick prayers, or use the timer when you want a longer, dedicated session.",
                "Review the latest entries, recent resistance, and recent losses in one place.",
                "Keep everything in one timeline instead of moving between separate apps."
            ]
        ),
        .init(
            title: "Log with clarity",
            subtitle: "Choose the sin, choose the outcome, and add context when you need it so each entry tells the full story.",
            icon: "square.and.pencil",
            tint: .teal,
            points: [
                "Pick the exact sin from the section list.",
                "Mark resistance, loss, or note the moment so the entry reflects what actually happened.",
                "Optionally attach prayer time to a sin log if you prayed as part of the response.",
                "Use quick prayer separately when you just want to record the prayer itself."
            ]
        ),
        .init(
            title: "Understand purity",
            subtitle: "The percentage shows current purity for each struggle: 0% is rock bottom and 100% is pure.",
            icon: "chart.bar.fill",
            tint: .indigo,
            points: [
                "Losses, clean time, and your selected strictness decide the current purity level.",
                "Strictness controls how much history counts and how long a clean stretch must be before Pure.",
                "Resistance is counted separately so effort stays visible without distorting the purity score.",
                "Manual sliders create a new baseline when you know the current score needs a correction."
            ]
        ),
        .init(
            title: "Pray with purpose",
            subtitle: "Use the prayer timer when you want a dedicated, distraction-free session that you can save and revisit later.",
            icon: "timer",
            tint: .cyan,
            points: [
                "Start a timer from the Home screen or Prayer tab.",
                "Save elapsed minutes into the timeline automatically so the habit becomes visible over time.",
                "Use quick prayer for short entries when a timer is too much, or when you only want to capture a brief prayer.",
                "The timer gives you a cleaner way to separate focused prayer from a normal sin log."
            ]
        ),
        .init(
            title: "Change the atmosphere",
            subtitle: "Choose a theme that feels calm, clear, and easy to read, with enough contrast that the content stays comfortable in light or dark mode.",
            icon: "paintpalette.fill",
            tint: .purple,
            points: [
                "Switch backgrounds from Settings at any time.",
                "The interface keeps the same layout across themes so the app feels familiar while the colors change.",
                "Light and dark mode both stay readable, with backgrounds and text tuned for contrast.",
                "You can adjust the theme later without losing your entries or timeline."
            ]
        ),
        .init(
            title: "Enjoy the journey",
            subtitle: "The app is here to stay out of the way and give you a clear place to return to each day.",
            icon: "heart.fill",
            tint: .pink,
            points: [
                "Use the app at your own pace and let the habits build naturally.",
                "Come back when you want to log, pray, or review the path you’ve already walked.",
                "May it feel simple, steady, and useful every time you open it."
            ]
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .blood)

            VStack(spacing: 18) {
                if pageIndex < pages.count - 1 {
                    HStack {
                        Spacer()

                        Button("Skip") {
                            finish()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity)
                }

                TabView(selection: $pageIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageCard(page: pages[index])
                            .tag(index)
                            .padding(.horizontal, 16)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, minHeight: 540, maxHeight: .infinity, alignment: .top)
                .task(id: pageIndex) {
                    pageProgress = 0

                    guard pageIndex < pages.count - 1 else { return }

                    withAnimation(.linear(duration: autoAdvanceDuration)) {
                        pageProgress = 1
                    }

                    do {
                        try await Task.sleep(for: .seconds(autoAdvanceDuration))
                    } catch {
                        return
                    }

                    guard !Task.isCancelled, pageIndex < pages.count - 1 else { return }

                    withAnimation(.easeInOut(duration: 0.55)) {
                        pageIndex += 1
                    }
                }

                AppSurfaceCard(contentPadding: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        if pageIndex < pages.count - 1 {
                            HStack(spacing: 8) {
                                ForEach(pages.indices, id: \.self) { index in
                                    let isSelected = index == pageIndex
                                    let trackColor: Color = {
                                        if isSelected {
                                            return colorScheme == .dark ? .white.opacity(0.18) : .primary.opacity(0.12)
                                        } else {
                                            return .primary.opacity(0.14)
                                        }
                                    }()
                                    let fillColor: Color = colorScheme == .dark ? .white : .primary

                                    Capsule()
                                        .fill(trackColor)
                                        .frame(width: isSelected ? 22 : 8, height: 8)
                                        .overlay(alignment: .leading) {
                                            if isSelected {
                                                Capsule()
                                                    .fill(fillColor)
                                                    .frame(width: 22 * pageProgress, height: 8)
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                        }

                        ActionButtonView(
                            title: pageIndex == pages.count - 1 ? "Get Started" : "Continue",
                            icon: pageIndex == pages.count - 1 ? "checkmark" : "arrow.right",
                            tint: .red
                        ) {
                            advance()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .animation(.easeInOut(duration: 0.2), value: pageIndex)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func advance() {
        if pageIndex < pages.count - 1 {
            withAnimation(.easeInOut) {
                pageIndex += 1
            }
        } else {
            finish()
        }
    }

    private func finish() {
        isPresented = false
        onFinish()
    }
}

private struct OnboardingPageCard: View {
    let page: WelcomePage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppSurfaceCard(contentPadding: 16) {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    Circle()
                        .fill(page.tint.opacity(colorScheme == .dark ? 0.16 : 0.12))
                    Image(systemName: page.icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(page.tint)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 10) {
                    Text(page.title)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.points, id: \.self) { point in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(page.tint.opacity(0.18))
                                .frame(width: 9, height: 9)
                                .padding(.top, 7)

                            Text(point)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 540, alignment: .topLeading)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.04), radius: 14, x: 0, y: 8)
    }
}

private struct WelcomePage {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let points: [String]
}

#Preview {
    WelcomeView(isPresented: .constant(true), onFinish: {})
}
