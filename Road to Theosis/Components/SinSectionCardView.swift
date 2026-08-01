import SwiftUI

struct SinSectionCardView: View {
    @Binding var section: SinSection
    let isCompact: Bool
    let showsVictoryAction: Bool
    let usesProgressSliders: Bool
    let sliderStyle: FocusSliderStyle
    let focusedItemIDs: Set<SinCategory.ID>
    let onShowVerses: (SinCategory) -> Void
    let onFocus: (SinCategory.ID) -> Void
    let onVictory: (SinCategory.ID) -> Void
    let onReset: (SinCategory.ID) -> Void
    let onProgressChanged: (SinCategory.ID, Double) -> Void

    private var averageFrequencyText: String {
        SinFrequencyScale.label(for: section.averageProgress)
    }

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
                            Text("\(SinFrequencyScale.percentage(for: section.averageProgress))%")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(section.tint)

                            Text(SinFrequencyScale.level(for: section.averageProgress).title.uppercased())
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

                    HStack(spacing: 8) {
                        Text("Average frequency: \(averageFrequencyText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Text("\(section.itemCount) items")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                if section.isExpanded {
                    VStack(spacing: 0) {
                        ForEach(section.items.indices, id: \.self) { index in
                            CategoryCardView(
                                category: $section.items[index],
                                isCompact: isCompact,
                                showsVictoryAction: showsVictoryAction,
                                usesProgressSlider: usesProgressSliders,
                                sliderStyle: sliderStyle,
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
                            } onProgressChanged: { progress in
                                onProgressChanged(section.items[index].id, progress)
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
        showsVictoryAction: true,
        usesProgressSliders: true,
        sliderStyle: .marked,
        focusedItemIDs: [SinCategory.sample[0].items[0].id],
        onShowVerses: { _ in },
        onFocus: { _ in },
        onVictory: { _ in },
        onReset: { _ in },
        onProgressChanged: { _, _ in }
    )
    .padding()
}
