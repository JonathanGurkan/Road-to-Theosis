import SwiftUI

struct SinSectionCardView: View {
    @Binding var section: SinSection
    let isCompact: Bool
    let onShowVerses: (SinCategory) -> Void
    let onVictory: (SinCategory.ID) -> Void
    let onReset: (SinCategory.ID) -> Void

    var body: some View {
        AppSurfaceCard(contentPadding: 12) {
            VStack(alignment: .leading, spacing: isCompact ? 10 : 12) {
                Button {
                    section.isExpanded.toggle()
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(section.tint.opacity(0.16))

                            Image(systemName: section.isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(section.tint)
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(section.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(section.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(Int(section.averageProgress * 100))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(section.tint)

                            Text("\(section.itemCount) items")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.4)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: section.averageProgress)
                        .tint(section.tint)

                    Text("Swipe a row for quick actions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if section.isExpanded {
                    VStack(spacing: 0) {
                        ForEach(section.items.indices, id: \.self) { index in
                            CategoryCardView(
                                category: $section.items[index],
                                isCompact: isCompact,
                                onIconTap: {
                                    onShowVerses(section.items[index])
                                }
                            ) {
                                onVictory(section.items[index].id)
                            } onReset: {
                                onReset(section.items[index].id)
                            }

                            if index < section.items.count - 1 {
                                Divider()
                                    .padding(.leading, 46)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
