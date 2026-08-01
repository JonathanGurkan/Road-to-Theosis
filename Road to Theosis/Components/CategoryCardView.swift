import SwiftUI

struct CategoryCardView: View {
    @Binding var category: SinCategory
    let isCompact: Bool
    let showsVictoryAction: Bool
    let usesProgressSlider: Bool
    let sliderStyle: FocusSliderStyle
    let isFocused: Bool
    let onIconTap: () -> Void
    let onFocus: () -> Void
    let onVictory: () -> Void
    let onReset: () -> Void
    let onProgressChanged: (Double) -> Void
    @State private var progressAtDragStart: Double?

    private var progressPercentage: Int {
        SinFrequencyScale.percentage(for: category.progress)
    }

    private var frequencyLevel: SinFrequencyLevel {
        SinFrequencyScale.level(for: progressPercentage)
    }

    private var progressText: String {
        "\(progressPercentage)%"
    }

    private var swipeActions: SinSwipeActions {
        category.swipeActions
    }

    var body: some View {
        if usesProgressSlider {
            cardContent
        } else {
            cardContent
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if showsVictoryAction {
                        Button(action: onVictory) {
                            Label(swipeActions.victoryTitle, systemImage: swipeActions.victoryIcon)
                        }
                        .tint(.green)
                    }

                    Button(role: .destructive, action: onReset) {
                        Label(swipeActions.stumbleTitle, systemImage: swipeActions.stumbleIcon)
                    }
                }
        }
    }

    private var cardContent: some View {
        VStack(spacing: isCompact ? 8 : 10) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onIconTap) {
                    ZStack {
                        Circle()
                            .fill(category.tint.opacity(0.16))

                        Image(systemName: category.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(category.tint)
                    }
                    .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open defense verses for \(category.title)")

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(category.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(progressText)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(category.tint)

                    Text(category.watchword.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.4)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Button(action: onFocus) {
                        Text(isFocused ? "Remove Focus" : "Focus")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isFocused ? .white : category.tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                isFocused ? category.tint : category.tint.opacity(0.13),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Set \(category.title) as today's focus")
                }
            }

            if usesProgressSlider {
                VStack(alignment: .leading, spacing: sliderStyle == .compact ? 4 : 6) {
                    FrequencySliderView(
                        value: $category.progress,
                        tint: category.tint,
                        style: sliderStyle,
                        accessibilityTitle: "\(category.title) frequency",
                        onEditingChanged: handleProgressEditingChanged
                    )

                    if sliderStyle.showsLegend {
                        frequencySummaryRow
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: category.progress)
                        .tint(category.tint)

                    frequencySummaryRow
                }
            }
        }
        .padding(.vertical, isCompact ? 8 : 10)
        .padding(.horizontal, isFocused ? 8 : 0)
        .background {
            if isFocused {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(category.tint.opacity(0.08))
            }
        }
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(category.tint.opacity(0.22), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .id(showsVictoryAction)
    }

    private var frequencySummaryRow: some View {
        HStack(spacing: 8) {
            Label(frequencyLevel.title, systemImage: "calendar.badge.clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(category.tint)

            Spacer(minLength: 8)

            Text(category.frequencyDescription(for: frequencyLevel))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    private func handleProgressEditingChanged(_ isEditing: Bool) {
        if isEditing {
            progressAtDragStart = category.progress
            return
        }

        defer { progressAtDragStart = nil }

        guard let progressAtDragStart,
              abs(progressAtDragStart - category.progress) >= 0.005 else {
            return
        }

        onProgressChanged(category.progress)
    }
}

private struct FrequencySliderView: View {
    @Binding var value: Double
    let tint: Color
    let style: FocusSliderStyle
    let accessibilityTitle: String
    let onEditingChanged: (Bool) -> Void
    @State private var isEditing = false

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var accessibilityValue: String {
        SinFrequencyScale.label(for: clampedValue)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let thumbSize = style.thumbSize
            let xPosition = min(max(clampedValue * width, thumbSize / 2), width - thumbSize / 2)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: style.trackHeight / 2, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(height: style.trackHeight)

                RoundedRectangle(cornerRadius: style.trackHeight / 2, style: .continuous)
                    .fill(tint.gradient)
                    .frame(width: max(thumbSize / 2, xPosition), height: style.trackHeight)

                if style.showsMilestones {
                    ForEach(SinFrequencyScale.milestoneProgresses, id: \.self) { milestone in
                        let indicatorWidth: CGFloat = 10
                        let indicatorHeight: CGFloat = 3
                        let position = min(max(CGFloat(milestone) * width, indicatorWidth / 2), width - indicatorWidth / 2)
                        Capsule()
                            .fill(tint.opacity(milestone <= clampedValue ? style.milestoneOpacity.active : style.milestoneOpacity.inactive))
                            .frame(width: indicatorWidth, height: indicatorHeight)
                            .position(x: position, y: style.controlHeight - 4)
                    }
                }

                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .overlay(Circle().stroke(tint, lineWidth: 3))
                    .shadow(color: tint.opacity(0.25), radius: 6, x: 0, y: 2)
                    .frame(width: thumbSize, height: thumbSize)
                    .position(x: xPosition, y: style.controlHeight / 2)
            }
            .frame(height: style.controlHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        beginEditingIfNeeded()
                        updateValue(with: gesture.location.x, width: width)
                    }
                    .onEnded { gesture in
                        updateValue(with: gesture.location.x, width: width)
                        endEditingIfNeeded()
                    }
            )
        }
        .frame(height: style.controlHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            beginEditingIfNeeded()
            switch direction {
            case .increment:
                value = min(1, clampedValue + 0.05)
            case .decrement:
                value = max(0, clampedValue - 0.05)
            @unknown default:
                break
            }
            endEditingIfNeeded()
        }
    }

    private func beginEditingIfNeeded() {
        guard !isEditing else { return }
        isEditing = true
        onEditingChanged(true)
    }

    private func endEditingIfNeeded() {
        guard isEditing else { return }
        isEditing = false
        value = Double(SinFrequencyScale.percentage(for: value)) / 100
        onEditingChanged(false)
    }

    private func updateValue(with locationX: CGFloat, width: CGFloat) {
        let rawValue = min(max(locationX / max(width, 1), 0), 1)
        value = Double(rawValue)
    }
}

#Preview {
    CategoryCardView(
        category: .constant(SinCategory.sample[0].items[0]),
        isCompact: false,
        showsVictoryAction: true,
        usesProgressSlider: true,
        sliderStyle: .marked,
        isFocused: true,
        onIconTap: { },
        onFocus: { },
        onVictory: { },
        onReset: { },
        onProgressChanged: { _ in }
    )
    .padding()
}
