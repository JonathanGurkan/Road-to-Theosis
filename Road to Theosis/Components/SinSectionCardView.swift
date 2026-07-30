import SwiftUI

struct SinSectionCardView: View {
    @Binding var section: SinSection
    let isCompact: Bool
    let focusedItemIDs: Set<SinCategory.ID>
    let onShowVerses: (SinCategory) -> Void
    let onFocus: (SinCategory.ID) -> Void
    let onVictory: (SinCategory.ID) -> Void
    let onReset: (SinCategory.ID) -> Void
    let onSetProgress: (SinCategory.ID) -> Void

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

                    Text("Choose a focus, then act from the panel above.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if section.isExpanded {
                    VStack(spacing: 0) {
                        ForEach(section.items.indices, id: \.self) { index in
                            CategoryCardView(
                                category: $section.items[index],
                                isCompact: isCompact,
                                isFocused: focusedItemIDs.contains(section.items[index].id),
                                onIconTap: {
                                    onShowVerses(section.items[index])
                                },
                                onFocus: {
                                    onFocus(section.items[index].id)
                                }
                            ) {
                                onVictory(section.items[index].id)
                            } onReset: {
                                onReset(section.items[index].id)
                            } onSetProgress: {
                                onSetProgress(section.items[index].id)
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

#Preview {
    SinSectionCardView(
        section: .constant(SinCategory.sample[0]),
        isCompact: false,
        focusedItemIDs: [SinCategory.sample[0].items[0].id],
        onShowVerses: { _ in },
        onFocus: { _ in },
        onVictory: { _ in },
        onReset: { _ in },
        onSetProgress: { _ in }
    )
    .padding()
}
