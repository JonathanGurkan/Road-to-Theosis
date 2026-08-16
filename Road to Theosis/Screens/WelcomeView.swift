import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool
    let onStartCalibration: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var pageIndex = 0

    private let pages: [FeatureOverviewPage] = [
        .dashboard,
        .logging,
        .timeline,
        .settings
    ]

    var body: some View {
        ZStack(alignment: .top) {
            AppBackgroundView(theme: .blood)

            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.14 : 0.06),
                    Color.clear,
                    Color.red.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    overviewHeader

                FeatureOverviewCard(page: pages[pageIndex], pageNumber: pageIndex + 1, pageCount: pages.count)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .gesture(
                        DragGesture(minimumDistance: 32)
                            .onEnded(handleOverviewDrag)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 150)
            }
        }
        .safeAreaInset(edge: .bottom) {
            overviewFooter
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(.clear)
        }
        .interactiveDismissDisabled()
    }

    private var overviewHeader: some View {
        AppSurfaceCard(contentPadding: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.22 : 0.14))

                    Image(systemName: "sparkles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 7) {
                    Text("Welcome to Road to Theosis")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Here is the short version of what the app helps you do. After this, a check-in calibrates your starting point.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var overviewFooter: some View {
        OnboardingPagerFooter(
            tint: pages[pageIndex].tint,
            pageColors: pages.map(\.tint),
            selectedIndex: pageIndex,
            pageLabel: "Page \(pageIndex + 1) of \(pages.count)",
            currentTitle: nil,
            message: pageIndex == pages.count - 1 ? "Next is the calibration check-in. It is required so the app starts from your real answers." : "Continue through the app overview at your own pace.",
            showsBackButton: pageIndex > 0,
            forwardTitle: pageIndex == pages.count - 1 ? "Start Calibration" : "Continue",
            forwardIcon: pageIndex == pages.count - 1 ? "calendar.badge.checkmark" : "arrow.right",
            onBack: goBackOverview,
            onForward: advanceOverview
        )
        .animation(.easeInOut(duration: 0.2), value: pageIndex)
    }

    private func goBackOverview() {
        guard pageIndex > 0 else { return }

        withAnimation(.easeInOut) {
            pageIndex -= 1
        }
    }

    private func advanceOverview() {
        if pageIndex < pages.count - 1 {
            withAnimation(.easeInOut) {
                pageIndex += 1
            }
        } else {
            isPresented = false
            onStartCalibration()
        }
    }

    private func handleOverviewDrag(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        guard abs(horizontalAmount) > abs(verticalAmount) else { return }

        if horizontalAmount < -44 {
            advanceOverview()
        } else if horizontalAmount > 44 {
            goBackOverview()
        }
    }
}

private struct FeatureOverviewCard: View {
    let page: FeatureOverviewPage
    let pageNumber: Int
    let pageCount: Int

    var body: some View {
        OnboardingFeatureCard(
            title: page.title,
            subtitle: page.subtitle,
            symbol: page.symbol,
            tint: page.tint,
            badgeText: "\(pageNumber)/\(pageCount)",
            highlights: page.points
        )
    }
}

private struct OnboardingPagerFooter: View {
    let tint: Color
    let pageColors: [Color]
    let selectedIndex: Int
    let pageLabel: String
    let currentTitle: String?
    let message: String
    let showsBackButton: Bool
    let forwardTitle: String
    let forwardIcon: String
    var dotProgress: Double?
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                OnboardingProgressDots(
                    colors: pageColors,
                    selectedIndex: selectedIndex,
                    activeProgress: dotProgress
                )

                HStack {
                    Text(pageLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let currentTitle {
                        Spacer(minLength: 8)

                        Text(currentTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tint)
                            .lineLimit(1)
                    }
                }

                Text(message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    if showsBackButton {
                        ActionButtonView(title: "Back", icon: "chevron.left", tint: tint, action: onBack)
                            .frame(maxWidth: .infinity)
                    }

                    ActionButtonView(title: forwardTitle, icon: forwardIcon, tint: tint, action: onForward)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct OnboardingProgressDots: View {
    let colors: [Color]
    let selectedIndex: Int
    let activeProgress: Double?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(colors.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? colors[index] : .primary.opacity(0.14))
                    .frame(width: index == selectedIndex ? 24 : 8, height: 8)
                    .overlay(alignment: .leading) {
                        if index == selectedIndex, let activeProgress {
                            Capsule()
                                .fill(colorScheme == .dark ? .white : .primary)
                                .frame(width: 24 * activeProgress, height: 8)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct OnboardingFeatureCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let badgeText: String
    let highlights: [WelcomeHighlight]
    var isCompact = false
    var detailsTitle: String?
    var onShowDetails: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppSurfaceCard(contentPadding: 16) {
            VStack(alignment: .leading, spacing: isCompact ? 16 : 14) {
                hero

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(highlights.indices, id: \.self) { index in
                        GuideBulletRow(highlight: highlights[index], tint: tint)
                    }
                }

                if let detailsTitle, let onShowDetails {
                    Button(action: onShowDetails) {
                        Label(detailsTitle, systemImage: "rectangle.stack.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    tint.opacity(colorScheme == .dark ? 0.28 : 0.18),
                    tint.opacity(colorScheme == .dark ? 0.08 : 0.06),
                    Color.primary.opacity(colorScheme == .dark ? 0.03 : 0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: symbol)
                .font(.system(size: isCompact ? 94 : 92, weight: .bold))
                .foregroundStyle(tint.opacity(colorScheme == .dark ? 0.10 : 0.08))
                .offset(x: isCompact ? 20 : 24, y: isCompact ? -20 : -24)

            VStack(alignment: .leading, spacing: isCompact ? 14 : 12) {
                Text(badgeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.14), in: Capsule())

                Image(systemName: symbol)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(isCompact ? .callout : .body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(isCompact ? 18 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct FeatureOverviewPage {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let points: [WelcomeHighlight]

    static let dashboard = FeatureOverviewPage(
        title: "See your day clearly",
        subtitle: "Home gathers the pieces you need most so the app opens to a calm, useful overview.",
        symbol: "house.fill",
        tint: .red,
        points: [
            .init(symbol: "scope", title: "Current focus", detail: "Keep the struggle you are watching most closely near the top."),
            .init(symbol: "bolt.fill", title: "Fast actions", detail: "Start prayer or add a log without digging through screens."),
            .init(symbol: "square.grid.2x2.fill", title: "Editable layout", detail: "Rearrange the home cards later from Settings.")
        ]
    )

    static let logging = FeatureOverviewPage(
        title: "Record what happened",
        subtitle: "Logs turn moments into something you can review, pray through, and learn from.",
        symbol: "square.and.pencil",
        tint: .teal,
        points: [
            .init(symbol: "checkmark.shield.fill", title: "Victories and losses", detail: "Save the outcome without writing more than you need."),
            .init(symbol: "text.quote", title: "Notes when useful", detail: "Add context when it helps you understand the pattern."),
            .init(symbol: "timer", title: "Prayer time", detail: "Keep prayer connected to the moment it answered.")
        ]
    )

    static let timeline = FeatureOverviewPage(
        title: "Review your patterns",
        subtitle: "The timeline keeps prayers, notes, check-ins, and logs in order so your progress is easier to read.",
        symbol: "clock.arrow.circlepath",
        tint: .indigo,
        points: [
            .init(symbol: "calendar", title: "Grouped by day", detail: "See what happened without piecing it together yourself."),
            .init(symbol: "pencil", title: "Editable entries", detail: "Clean up details later when you remember more."),
            .init(symbol: "chart.line.uptrend.xyaxis", title: "Visible movement", detail: "Notice repeated pressure points and real growth.")
        ]
    )

    static let settings = FeatureOverviewPage(
        title: "Tune the app around you",
        subtitle: "Settings keeps the personal choices together: theme, strictness, reminders, Scripture, and help.",
        symbol: "gearshape.fill",
        tint: .purple,
        points: [
            .init(symbol: "paintpalette.fill", title: "Theme", detail: "Pick the look that is easiest to read and return to."),
            .init(symbol: "calendar.badge.checkmark", title: "Check-ins", detail: "Choose reminders and which questions appear."),
            .init(symbol: "questionmark.circle.fill", title: "Help guide", detail: "Open the guide any time after setup.")
        ]
    )
}

struct HelpGuideView: View {
    @Binding var isPresented: Bool
    let onFinish: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var stepIndex: Int = 0
    @State private var stepProgress: Double = 0
    @State private var isShowingStepDetails = false
    private let autoAdvanceDuration: Double = 12

    private let steps: [WelcomeStep] = [
        .home,
        .logging,
        .timeline,
        .settings
    ]

    var body: some View {
        ZStack(alignment: .top) {
            AppBackgroundView(theme: .blood)

            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08),
                    Color.clear,
                    Color.red.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                        .padding(.horizontal, 16)

                    stepRail
                        .padding(.horizontal, 16)

                    CompactGuideStepCard(
                        step: steps[stepIndex],
                        stepNumber: stepIndex + 1,
                        stepCount: steps.count
                    ) {
                        isShowingStepDetails = true
                    }
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 32)
                            .onEnded(handleGuideDrag)
                    )
                    .task(id: stepIndex) {
                        stepProgress = 0

                        guard stepIndex < steps.count - 1 else { return }

                        withAnimation(.linear(duration: autoAdvanceDuration)) {
                            stepProgress = 1
                        }

                        do {
                            try await Task.sleep(for: .seconds(autoAdvanceDuration))
                        } catch {
                            return
                        }

                        guard !Task.isCancelled, stepIndex < steps.count - 1 else { return }

                        withAnimation(.easeInOut(duration: 0.55)) {
                            stepIndex += 1
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(.clear)
        }
        .sheet(isPresented: $isShowingStepDetails) {
            GuideStepDetailSheet(step: steps[stepIndex], stepNumber: stepIndex + 1, stepCount: steps.count)
        }
    }

    private var header: some View {
        AppSurfaceCard(contentPadding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.red.opacity(colorScheme == .dark ? 0.28 : 0.18),
                                        Color.orange.opacity(colorScheme == .dark ? 0.18 : 0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Image(systemName: "sparkles")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Road to Theosis Guide")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("A reusable guide to the screens and tools you can come back to whenever you need a refresher.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    if stepIndex < steps.count - 1 {
                        Button("Close") {
                            finish()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Label("4 calm steps", systemImage: "list.number")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.12), in: Capsule())

                    Label("You stay in control", systemImage: "hand.wave.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.05), in: Capsule())

                    Spacer(minLength: 0)
                }

                Text("Use this guide as a reference. Closing it never changes your setup or calibration.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var stepRail: some View {
        AppSurfaceCard(contentPadding: 12) {
            HStack(spacing: 10) {
                ForEach(steps.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            stepIndex = index
                        }
                    } label: {
                        GuideStepRailItem(
                            step: steps[index],
                            isSelected: index == stepIndex,
                            isCompleted: index < stepIndex
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(steps[index].shortTitle), step \(index + 1) of \(steps.count)")
                }
            }
        }
    }

    private var footer: some View {
        OnboardingPagerFooter(
            tint: steps[stepIndex].tint,
            pageColors: steps.map(\.tint),
            selectedIndex: stepIndex,
            pageLabel: "Step \(stepIndex + 1) of \(steps.count)",
            currentTitle: steps[stepIndex].shortTitle,
            message: stepIndex == steps.count - 1 ? "You're ready to begin." : "Take your time. Use the controls below when you're ready.",
            showsBackButton: stepIndex > 0,
            forwardTitle: stepIndex == steps.count - 1 ? "Start Exploring" : "Continue",
            forwardIcon: stepIndex == steps.count - 1 ? "checkmark.circle.fill" : "arrow.right",
            dotProgress: stepProgress,
            onBack: goBack,
            onForward: advance
        )
        .animation(.easeInOut(duration: 0.2), value: stepIndex)
    }

    private func goBack() {
        guard stepIndex > 0 else { return }

        withAnimation(.easeInOut) {
            stepIndex -= 1
        }
    }

    private func advance() {
        if stepIndex < steps.count - 1 {
            withAnimation(.easeInOut) {
                stepIndex += 1
            }
        } else {
            finish()
        }
    }

    private func finish() {
        isPresented = false
        onFinish()
    }

    private func handleGuideDrag(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        guard abs(horizontalAmount) > abs(verticalAmount) else { return }

        if horizontalAmount < -44 {
            advance()
        } else if horizontalAmount > 44 {
            goBack()
        }
    }
}

struct OnboardingSuccessView: View {
    let onContinue: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .blood)

            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08),
                    Color.clear,
                    Color.green.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer(minLength: 20)

                AppSurfaceCard(contentPadding: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(colorScheme == .dark ? 0.22 : 0.16))

                            Image(systemName: "checkmark.seal.fill")
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calibration Complete")
                                .font(.title.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Your starting check-in is saved. The dashboard now has a real baseline, and you can adjust settings or keep logging from here.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            GuideBulletRow(
                                highlight: .init(symbol: "house.fill", title: "Dashboard calibrated", detail: "Your first answers are reflected in the app's starting state."),
                                tint: .green
                            )

                            GuideBulletRow(
                                highlight: .init(symbol: "clock.arrow.circlepath", title: "Timeline started", detail: "The check-in was saved as your first whole-journey entry."),
                                tint: .teal
                            )
                        }
                    }
                }

                ActionButtonView(title: "Enter App", icon: "arrow.right", tint: .green, action: onContinue)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .interactiveDismissDisabled()
    }
}

private struct GuideStepCard: View {
    let step: WelcomeStep
    let stepNumber: Int
    let stepCount: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppSurfaceCard(contentPadding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                stepHero

                VStack(alignment: .leading, spacing: 18) {
                    step.preview
                }
            }
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.04), radius: 14, x: 0, y: 8)
    }

    private var stepHero: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    step.tint.opacity(colorScheme == .dark ? 0.28 : 0.18),
                    step.tint.opacity(colorScheme == .dark ? 0.08 : 0.06),
                    Color.primary.opacity(colorScheme == .dark ? 0.03 : 0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: step.icon)
                .font(.system(size: 112, weight: .bold))
                .foregroundStyle(step.tint.opacity(colorScheme == .dark ? 0.10 : 0.08))
                .offset(x: 22, y: -22)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("Step \(stepNumber)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text("\(stepNumber)/\(stepCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(step.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(step.tint.opacity(0.14), in: Capsule())
                }

                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(step.tint.opacity(colorScheme == .dark ? 0.18 : 0.14))
                        Image(systemName: step.icon)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(step.tint)
                    }
                    .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.title)
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(step.subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct CompactGuideStepCard: View {
    let step: WelcomeStep
    let stepNumber: Int
    let stepCount: Int
    let onShowDetails: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        OnboardingFeatureCard(
            title: step.title,
            subtitle: step.subtitle,
            symbol: step.icon,
            tint: step.tint,
            badgeText: "Step \(stepNumber) / \(stepCount)",
            highlights: step.highlights,
            isCompact: true,
            detailsTitle: "Learn More",
            onShowDetails: onShowDetails
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.04), radius: 14, x: 0, y: 8)
    }
}

private struct GuideStepDetailSheet: View {
    let step: WelcomeStep
    let stepNumber: Int
    let stepCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: .blood)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        GuideStepCard(step: step, stepNumber: stepNumber, stepCount: stepCount)

                        if let note = step.note {
                            AppSurfaceCard(contentPadding: 14) {
                                Label(note, systemImage: "lightbulb.fill")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(step.shortTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct GuideBulletRow: View {
    let highlight: WelcomeHighlight
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                Image(systemName: highlight.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(highlight.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GuideStepRailItem: View {
    let step: WelcomeStep
    let isSelected: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? step.tint.opacity(0.22) : (isCompleted ? step.tint.opacity(0.14) : Color.primary.opacity(0.08)))
                Image(systemName: step.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? step.tint : (isCompleted ? step.tint : .secondary))
            }
            .frame(width: 32, height: 32)

            Text(step.shortTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

private struct HomeGuidePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Home screen", systemImage: "house.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Customize in Settings")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
            }

            GuideStatusStrip(
                title: "Today",
                value: "Prayer logged",
                symbol: "checkmark.seal.fill",
                tint: .green
            )

            HStack(spacing: 10) {
                GuidePreviewTile(title: "Greeting", subtitle: "Daily welcome", symbol: "sun.max.fill", tint: .yellow)
                GuidePreviewTile(title: "Quick actions", subtitle: "Prayer + log", symbol: "bolt.fill", tint: .orange)
            }

            HStack(spacing: 10) {
                GuidePreviewTile(title: "Recent activity", subtitle: "Latest entries", symbol: "clock.arrow.circlepath", tint: .cyan, isProminent: true)
                GuidePreviewTile(title: "Focus widget", subtitle: "One sin at a time", symbol: "scope", tint: .green)
            }

            GuidePreviewTile(title: "Settings", subtitle: "Resize and reorder cards", symbol: "gearshape.fill", tint: .gray)
        }
    }
}

private struct LoggingGuidePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Add logging", systemImage: "square.and.pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Choose the exact sin")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
            }

            GuideStatusStrip(
                title: "Helpful pace",
                value: "About 30 sec",
                symbol: "timer",
                tint: .teal
            )

            VStack(spacing: 8) {
                GuideActionLine(symbol: "list.bullet.rectangle", title: "Pick the sin", detail: "Choose the exact issue, not just the broad category.", tint: .teal)
                GuideActionLine(symbol: "checkmark.shield.fill", title: "Mark what happened", detail: "Save a victory, loss, note, or purity update.", tint: .red)
                GuideActionLine(symbol: "timer", title: "Attach prayer time", detail: "Add prayer minutes when the response includes prayer.", tint: .cyan)
                GuideActionLine(symbol: "plus.circle.fill", title: "Save it", detail: "The entry lands in the timeline immediately.", tint: .orange)
            }
        }
    }
}

private struct TimelineGuidePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Timeline", systemImage: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Review by day")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
            }

            GuideStatusStrip(
                title: "Today",
                value: "3 entries",
                symbol: "calendar",
                tint: .indigo
            )

            VStack(spacing: 8) {
                TimelinePreviewRow(title: "Prayer", detail: "8 min prayer session", symbol: "hands.sparkles.fill", tint: .cyan)
                TimelinePreviewRow(title: "Loss", detail: "Criticism in the morning", symbol: "xmark.circle.fill", tint: .orange)
                TimelinePreviewRow(title: "Note", detail: "Reflections and patterns", symbol: "text.quote", tint: .blue)
            }
        }
    }
}

private struct SettingsGuidePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Settings", systemImage: "gearshape.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Tune the app")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
            }

            GuideStatusStrip(
                title: "Personal setup",
                value: "Editable anytime",
                symbol: "slider.horizontal.3",
                tint: .purple
            )

            VStack(spacing: 8) {
                GuideActionLine(symbol: "paintpalette.fill", title: "Change the theme", detail: "Pick the atmosphere that feels easiest to read.", tint: .purple)
                GuideActionLine(symbol: "square.grid.2x2.fill", title: "Reshape the home screen", detail: "Reorder, resize, or hide cards from the layout editor.", tint: .red)
                GuideActionLine(symbol: "book.fill", title: "Manage your tools", detail: "Verses, strictness, and other support settings live here too.", tint: .green)
            }
        }
    }
}

private struct GuideStatusStrip: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 28, height: 28)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct GuideActionLine: View {
    let symbol: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GuidePreviewTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    var isProminent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.16))
                    Image(systemName: symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 28, height: 28)

                Spacer(minLength: 0)
            }

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(subtitle)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: isProminent ? 92 : 82, alignment: .leading)
        .background(Color.primary.opacity(isProminent ? 0.075 : 0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isProminent ? tint.opacity(0.35) : Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct TimelinePreviewRow: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct WelcomeStep {
    let title: String
    let shortTitle: String
    let subtitle: String
    let icon: String
    let tint: Color
    let highlights: [WelcomeHighlight]
    let note: String?
    let preview: AnyView

    static let home = WelcomeStep(
        title: "Begin at Home",
        shortTitle: "Home",
        subtitle: "Home gives you a steady place to land: your focus, recent movement, and the next helpful action.",
        icon: "house.fill",
        tint: .red,
        highlights: [
            .init(symbol: "square.grid.2x2.fill", title: "See what matters first", detail: "Your most useful cards stay easy to reach, and you can rearrange them later."),
            .init(symbol: "bolt.fill", title: "Act without searching", detail: "Prayer, logging, and check-ins are close by when you need them."),
            .init(symbol: "clock.arrow.circlepath", title: "Keep context visible", detail: "Recent entries and your current focus stay in view without digging through menus.")
        ],
        note: "Start simple. You can make Home feel more personal once you know what you use most.",
        preview: AnyView(HomeGuidePreview())
    )

    static let logging = WelcomeStep(
        title: "Log the moment",
        shortTitle: "Log",
        subtitle: "When something happens, capture it clearly enough that tomorrow-you can understand it.",
        icon: "square.and.pencil",
        tint: .teal,
        highlights: [
            .init(symbol: "list.bullet.rectangle", title: "Name it honestly", detail: "Pick the specific struggle instead of leaving it vague."),
            .init(symbol: "checkmark.shield.fill", title: "Record the outcome", detail: "Save a victory, a loss, a note, or a purity update."),
            .init(symbol: "timer", title: "Keep prayer attached", detail: "If prayer was part of your response, keep that time with the entry.")
        ],
        note: "A short, honest log is enough. This is about clarity, not perfection.",
        preview: AnyView(LoggingGuidePreview())
    )

    static let timeline = WelcomeStep(
        title: "Notice patterns",
        shortTitle: "Timeline",
        subtitle: "The timeline turns scattered entries into a readable story, grouped by day and ordered by time.",
        icon: "clock.arrow.circlepath",
        tint: .indigo,
        highlights: [
            .init(symbol: "calendar", title: "Read the day clearly", detail: "Entries are grouped so the shape of each day is easier to follow."),
            .init(symbol: "pencil", title: "Adjust details later", detail: "Open a row if you remember more or want to clean something up."),
            .init(symbol: "chart.line.uptrend.xyaxis", title: "Look for movement", detail: "The timeline helps you see growth, pressure points, and repeated patterns.")
        ],
        note: "This is the place to review without judging yourself in the heat of the moment.",
        preview: AnyView(TimelineGuidePreview())
    )

    static let settings = WelcomeStep(
        title: "Make it yours",
        shortTitle: "Settings",
        subtitle: "Settings keeps the personal parts in one place: appearance, prayer timing, layout, verses, and support tools.",
        icon: "gearshape.fill",
        tint: .purple,
        highlights: [
            .init(symbol: "paintpalette.fill", title: "Choose a calmer look", detail: "Pick a theme that feels easy to read and easy to return to."),
            .init(symbol: "square.grid.2x2.fill", title: "Shape your Home screen", detail: "Resize, hide, or rearrange cards from the layout editor."),
            .init(symbol: "book.fill", title: "Tune the support", detail: "Verses, strictness, reminders, and related preferences live here too.")
        ],
        note: "Nothing has to be perfect on day one. Adjust the app when you notice what helps.",
        preview: AnyView(SettingsGuidePreview())
    )
}

private struct WelcomeHighlight {
    let symbol: String
    let title: String
    let detail: String
}

#Preview("Welcome") {
    WelcomeView(isPresented: .constant(true), onStartCalibration: {})
}

#Preview("Help Guide") {
    HelpGuideView(isPresented: .constant(true), onFinish: {})
}
