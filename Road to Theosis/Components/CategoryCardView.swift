import SwiftUI

struct CategoryCardView: View {
    @Binding var category: SinCategory
    let isCompact: Bool
    let showsVictoryAction: Bool
    let usesProgressSlider: Bool
    let onIconTap: () -> Void
    let onVictory: () -> Void
    let onReset: () -> Void
    let onProgressChanged: (Double) -> Void
    @State private var progressAtDragStart: Double?

    private var progressText: String {
        "\(Int(category.progress * 100))%"
    }

    private var swipeActions: SinSwipeActions {
        category.swipeActions
    }

    var body: some View {
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

                VStack(alignment: .trailing, spacing: 3) {
                    Text(progressText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.tint)

                    Text(category.watchword.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.4)
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
        .contentShape(Rectangle())
        .id(showsVictoryAction)
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

#Preview {
    CategoryCardView(
        category: .constant(SinCategory.sample[0].items[0]),
        isCompact: false,
        showsVictoryAction: true,
        usesProgressSlider: true,
        onIconTap: { },
        onVictory: { },
        onReset: { },
        onProgressChanged: { _ in }
    )
    .padding()
}
