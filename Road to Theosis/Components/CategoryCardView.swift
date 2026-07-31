import SwiftUI

struct CategoryCardView: View {
    @Binding var category: SinCategory
    let isCompact: Bool
    let showsVictoryAction: Bool
    let usesProgressSlider: Bool
    let isFocused: Bool
    let onIconTap: () -> Void
    let onFocus: () -> Void
    let onVictory: () -> Void
    let onReset: () -> Void
    let onProgressChanged: (Double) -> Void
    @State private var progressAtDragStart: Double?
    let onSetProgress: () -> Void

    private var progressText: String {
        "\(Int(category.progress * 100))%"
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
                        .foregroundStyle(category.tint)

                    Text(category.watchword.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.4)

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
                Slider(
                    value: $category.progress,
                    in: 0...1,
                    step: 0.01
                ) { isEditing in
                    handleProgressEditingChanged(isEditing)
                }
                .tint(category.tint)
            } else {
                ProgressView(value: category.progress)
                    .tint(category.tint)
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

    private func handleProgressEditingChanged(_ isEditing: Bool) {
        if isEditing {
            progressAtDragStart = category.progress
            return
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onVictory) {
                Label(swipeActions.victoryTitle, systemImage: swipeActions.victoryIcon)
            }
            .tint(.green)

            Button(action: onSetProgress) {
                Label(swipeActions.progressTitle, systemImage: "slider.horizontal.3")
            }
            .tint(.blue)

            Button(role: .destructive, action: onReset) {
                Label(swipeActions.stumbleTitle, systemImage: swipeActions.stumbleIcon)
            }
        }

        defer { progressAtDragStart = nil }

        guard let progressAtDragStart,
              abs(progressAtDragStart - category.progress) >= 0.005 else {
            return
        }

        onProgressChanged(category.progress)
    }
}

#Preview {
    CategoryCardView(
        category: .constant(SinCategory.sample[0].items[0]),
        isCompact: false,
        showsVictoryAction: true,
        usesProgressSlider: true,
        isFocused: true,
        onIconTap: { },
        onFocus: { },
        onVictory: { },
        onReset: { },
        onProgressChanged: { _ in }
        onSetProgress: { }
    )
    .padding()
}
