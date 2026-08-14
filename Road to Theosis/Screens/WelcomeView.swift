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
                .frame(maxWidth: .infinity, minHeight: 560, maxHeight: .infinity, alignment: .top)
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
            .padding(.top, 12)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Guided tour")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text("Walk through the app")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("This tour moves in the same order you will use the app: Home, logging, Timeline, then Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if stepIndex < steps.count - 1 {
                    Button("Skip") {
                        finish()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
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
                            .frame(width: index == stepIndex ? 22 : 8, height: 8)
                            .overlay(alignment: .leading) {
                                if index == stepIndex {
                                    Capsule()
                                        .fill(colorScheme == .dark ? .white : .primary)
                                        .frame(width: 22 * stepProgress, height: 8)
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
                    Text(steps[stepIndex].title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(steps[stepIndex].tint)
                        .lineLimit(1)
                }

                ActionButtonView(
                    title: stepIndex == steps.count - 1 ? "Get Started" : "Continue Tour",
                    icon: stepIndex == steps.count - 1 ? "checkmark" : "arrow.right",
                    tint: .red
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
                                Text("Part \(stepNumber)")
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
                        Text("Look for this")
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
        title: "Start on the Home screen",
        shortTitle: "Home",
        subtitle: "The home screen is your dashboard. It shows the cards you use most and is where you can reshape the layout later.",
        icon: "house.fill",
        tint: .red,
        highlights: [
            .init(symbol: "square.grid.2x2.fill", title: "Reorder the cards", detail: "Move cards around and resize them from Settings when you want a different layout."),
            .init(symbol: "bolt.fill", title: "Use quick actions", detail: "Prayer and logging shortcuts live close to the top so you can move quickly."),
            .init(symbol: "clock.arrow.circlepath", title: "Watch recent activity", detail: "The latest entries and current focus stay visible without hunting through menus.")
        ],
        note: "This is the first place to customize if you want the app to feel more personal.",
        preview: AnyView(HomeGuidePreview())
    )

    static let logging = WelcomeStep(
        title: "Add a log entry",
        shortTitle: "Log",
        subtitle: "When something happens, record the exact struggle, mark the outcome, and attach prayer time if you prayed.",
        icon: "square.and.pencil",
        tint: .teal,
        highlights: [
            .init(symbol: "list.bullet.rectangle", title: "Pick the exact sin", detail: "Choose the specific struggle instead of only a broad category."),
            .init(symbol: "checkmark.shield.fill", title: "Mark what happened", detail: "Log a victory, a loss, a note, or a purity update."),
            .init(symbol: "timer", title: "Save prayer with it", detail: "Prayer time can be attached so the response is recorded with the log.")
        ],
        note: "The log screen is built to capture the story in one pass, not after the fact.",
        preview: AnyView(LoggingGuidePreview())
    )

    static let timeline = WelcomeStep(
        title: "Review the timeline",
        shortTitle: "Timeline",
        subtitle: "The timeline gathers prayers, resistance, losses, and notes in time order so you can see patterns clearly.",
        icon: "clock.arrow.circlepath",
        tint: .indigo,
        highlights: [
            .init(symbol: "calendar", title: "Read by day", detail: "Entries are grouped so the story is easier to follow."),
            .init(symbol: "pencil", title: "Edit when needed", detail: "Open a row to adjust a detail after you remember more."),
            .init(symbol: "chart.line.uptrend.xyaxis", title: "Watch growth over time", detail: "The timeline shows the shape of the journey, not just isolated moments.")
        ],
        note: "Use the timeline when you want a clean history instead of the more compact home summary.",
        preview: AnyView(TimelineGuidePreview())
    )

    static let settings = WelcomeStep(
        title: "Finish in Settings",
        shortTitle: "Settings",
        subtitle: "Settings is where you tune the app: theme, prayer timing, home layout, verses, and other support tools.",
        icon: "gearshape.fill",
        tint: .purple,
        highlights: [
            .init(symbol: "paintpalette.fill", title: "Change the atmosphere", detail: "Pick a look that feels calm and easy to read."),
            .init(symbol: "square.grid.2x2.fill", title: "Customize the home screen", detail: "Resize, hide, or rearrange cards from the layout editor."),
            .init(symbol: "book.fill", title: "Adjust support tools", detail: "Verse arsenal, strictness, and related preferences live here too.")
        ],
        note: "If you ever want the tour again, you can return to it from Settings.",
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
