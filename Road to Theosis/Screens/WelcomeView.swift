import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool
    let onFinish: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var stepIndex: Int = 0
    @State private var stepProgress: Double = 0
    private let autoAdvanceDuration: Double = 8

    private let steps: [WelcomeStep] = [
        .home,
        .logging,
        .timeline,
        .settings
    ]

    var body: some View {
        ZStack {
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

                    stepRail
                        .padding(.horizontal, 16)

                    TabView(selection: $stepIndex) {
                        ForEach(steps.indices, id: \.self) { index in
                            GuideStepCard(
                                step: steps[index],
                                stepNumber: index + 1,
                                stepCount: steps.count
                            )
                            .tag(index)
                            .padding(.horizontal, 16)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, minHeight: 610, idealHeight: 650, maxHeight: 700, alignment: .top)
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

                    footer
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .padding(.top, 24)
            }
            .safeAreaPadding(.top, 8)
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
                        Text("Welcome to Road to Theosis")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("A short walk-through so you know where everything lives before you start using it for real.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    if stepIndex < steps.count - 1 {
                        Button("Skip tour") {
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

                Text("Skip anything you already understand. You can reopen this from Settings whenever you want.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var stepRail: some View {
        AppSurfaceCard(contentPadding: 12) {
            HStack(spacing: 10) {
                ForEach(steps.indices, id: \.self) { index in
                    GuideStepRailItem(
                        step: steps[index],
                        isSelected: index == stepIndex,
                        isCompleted: index < stepIndex
                    )
                }
            }
        }
    }

    private var footer: some View {
        AppSurfaceCard(contentPadding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == stepIndex ? steps[index].tint : .primary.opacity(0.14))
                            .frame(width: index == stepIndex ? 24 : 8, height: 8)
                            .overlay(alignment: .leading) {
                                if index == stepIndex {
                                    Capsule()
                                        .fill(colorScheme == .dark ? .white : .primary)
                                        .frame(width: 24 * stepProgress, height: 8)
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Text("Step \(stepIndex + 1) of \(steps.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(steps[stepIndex].shortTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(steps[stepIndex].tint)
                        .lineLimit(1)
                }

                Text(stepIndex == steps.count - 1 ? "You're ready to begin." : "Take your time. You can swipe or use the button below.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                ActionButtonView(
                    title: stepIndex == steps.count - 1 ? "Start Exploring" : "Continue Tour",
                    icon: stepIndex == steps.count - 1 ? "checkmark.circle.fill" : "arrow.right",
                    tint: steps[stepIndex].tint
                ) {
                    advance()
                }
                .frame(maxWidth: .infinity)
            }
            .animation(.easeInOut(duration: 0.2), value: stepIndex)
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
}

private struct GuideStepCard: View {
    let step: WelcomeStep
    let stepNumber: Int
    let stepCount: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppSurfaceCard(contentPadding: 16) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(step.tint.opacity(colorScheme == .dark ? 0.16 : 0.12))
                            Image(systemName: step.icon)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(step.tint)
                        }
                        .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 4) {
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
                                    .background(step.tint.opacity(0.12), in: Capsule())
                            }

                            Text(step.title)
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(step.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }

                    step.preview

                    VStack(alignment: .leading, spacing: 12) {
                        Text("What to notice")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(step.highlights.indices, id: \.self) { index in
                                GuideBulletRow(highlight: step.highlights[index], tint: step.tint)
                            }
                        }
                    }

                    if let note = step.note {
                        Text(note)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(step.tint)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.04), radius: 14, x: 0, y: 8)
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

            VStack(spacing: 8) {
                GuideActionLine(symbol: "paintpalette.fill", title: "Change the theme", detail: "Pick the atmosphere that feels easiest to read.", tint: .purple)
                GuideActionLine(symbol: "square.grid.2x2.fill", title: "Reshape the home screen", detail: "Reorder, resize, or hide cards from the layout editor.", tint: .red)
                GuideActionLine(symbol: "book.fill", title: "Manage your tools", detail: "Verses, strictness, and other support settings live here too.", tint: .green)
            }
        }
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

#Preview {
    WelcomeView(isPresented: .constant(true), onFinish: {})
}
