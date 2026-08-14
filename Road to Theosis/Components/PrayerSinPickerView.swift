import SwiftUI

struct PrayerSinPickerView: View {
    let title: String
    let subtitle: String
    @Binding var selectedReferences: Set<ConnectedSinReference>

    @State private var selectedSectionIndex = 0

    private let sections = SinCategory.sample

    private var selectedSection: SinSection {
        sections[min(max(selectedSectionIndex, 0), sections.count - 1)]
    }

    private var selectedReferencesOrdered: [ConnectedSinReference] {
        ConnectedSinReference.ordered(selectedReferences)
    }

    private var summaryText: String {
        switch selectedReferencesOrdered.count {
        case 0:
            return "No sins attached"
        case 1:
            return "1 sin attached"
        default:
            return "\(selectedReferencesOrdered.count) sins attached"
        }
    }

    var body: some View {
        AppSurfaceCard(contentPadding: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text(summaryText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sections.indices, id: \.self) { index in
                            PrayerSinSectionChip(
                                title: sections[index].title,
                                tint: sections[index].tint,
                                isSelected: selectedSectionIndex == index,
                                count: sections[index].items.count
                            ) {
                                selectedSectionIndex = index
                            }
                        }
                    }
                    .padding(.vertical, 1)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(selectedSection.items, id: \.id) { item in
                        PrayerSinToggleChip(
                            category: item,
                            isSelected: selectedReferences.contains(.init(sectionTitle: selectedSection.title, sinTitle: item.title))
                        ) {
                            let reference = ConnectedSinReference(sectionTitle: selectedSection.title, sinTitle: item.title)
                            if selectedReferences.contains(reference) {
                                selectedReferences.remove(reference)
                            } else {
                                selectedReferences.insert(reference)
                            }
                        }
                    }
                }

                if !selectedReferencesOrdered.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected sins")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(selectedReferencesOrdered) { reference in
                                HStack(spacing: 8) {
                                    if let iconName = reference.resolvedIconName {
                                        Image(systemName: iconName)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(reference.displayTitle)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Spacer(minLength: 0)

                                    Button {
                                        selectedReferences.remove(reference)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20, height: 20)
                                            .background(Color.primary.opacity(0.06), in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Remove \(reference.displayTitle)")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PrayerSinSectionChip: View {
    let title: String
    let tint: Color
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(count) sins")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 102, alignment: .leading)
            .frame(minHeight: 46, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
                if #available(iOS 26.0, *) {
                    shape.fill(tint.opacity(isSelected ? 0.16 : 0.08))
                        .glassEffect(.regular, in: shape)
                } else {
                    shape.fill(tint.opacity(isSelected ? 0.18 : 0.10))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? tint.opacity(0.65) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrayerSinToggleChip: View {
    let category: SinCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(category.tint.opacity(isSelected ? 0.20 : 0.12))

                    Image(systemName: category.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.tint)
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(category.watchword)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(category.tint)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
                if #available(iOS 26.0, *) {
                    shape.fill(category.tint.opacity(isSelected ? 0.16 : 0.08))
                        .glassEffect(.regular, in: shape)
                } else {
                    shape.fill(category.tint.opacity(isSelected ? 0.18 : 0.10))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? category.tint.opacity(0.65) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
