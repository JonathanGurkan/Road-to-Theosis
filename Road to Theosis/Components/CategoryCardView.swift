import SwiftUI

struct CategoryCardView: View {
    @Binding var category: SinCategory
    let isCompact: Bool
    let showsVictoryAction: Bool
    let onIconTap: () -> Void
    let onVictory: () -> Void
    let onReset: () -> Void

    private var progressText: String {
        "\(Int(category.progress * 100))%"
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

            ProgressView(value: category.progress)
                .tint(category.tint)
        }
        .padding(.vertical, isCompact ? 8 : 10)
        .contentShape(Rectangle())
        .id(showsVictoryAction)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if showsVictoryAction {
                Button(action: onVictory) {
                    Label("Resist", systemImage: "shield.lefthalf.filled")
                }
                .tint(.green)
            }

            Button(role: .destructive, action: onReset) {
                Label("Stumble", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

#Preview {
    CategoryCardView(
        category: .constant(SinCategory.sample[0].items[0]),
        isCompact: false,
        showsVictoryAction: true,
        onIconTap: { },
        onVictory: { },
        onReset: { }
    )
    .padding()
}
