import SwiftUI
import UniformTypeIdentifiers

extension HeadwayView {
    func editableHomeCard(for configuration: HomeScreenCardConfiguration) -> some View {
        ZStack(alignment: .topLeading) {
            homeCard(for: configuration)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!isCustomizingHome)

            if isCustomizingHome {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .onDrag {
                            draggingHomeCardID = configuration.id
                            return NSItemProvider(object: configuration.id.rawValue as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: HomeCardDropDelegate(
                                targetID: configuration.id,
                                targetSize: proxy.size,
                                draggingID: $draggingHomeCardID
                            ) { sourceID, destinationID, insertAfter in
                                moveHomeCard(sourceID, relativeTo: destinationID, insertAfter: insertAfter)
                            }
                        )
                }

                ZStack(alignment: .topLeading) {
                    if configuration.id.supportsResizing && configuration.size == .minimal {
                        Menu {
                            Button {
                                moveHomeCard(configuration.id, by: -1)
                            } label: {
                                Label("Move Up", systemImage: "chevron.up")
                            }
                            .disabled(isFirstHomeCard(configuration.id))

                            Button {
                                moveHomeCard(configuration.id, by: 1)
                            } label: {
                                Label("Move Down", systemImage: "chevron.down")
                            }
                            .disabled(isLastHomeCard(configuration.id))

                            Picker("Size", selection: sizeBinding(for: configuration.id)) {
                                ForEach(HomeScreenCardSize.allCases) { size in
                                    Text(size.title).tag(size)
                                }
                            }

                            Button(role: .destructive) {
                                removeHomeCard(configuration.id)
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(backgroundTheme.glowColor)
                                .frame(width: 28, height: 28)
                                .background(.regularMaterial, in: Circle())
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(5)
                    } else {
                        Button {
                            removeHomeCard(configuration.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3.weight(.semibold))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                                .shadow(radius: 3)
                        }
                        .padding(6)

                        HStack(spacing: 8) {
                            Spacer()

                            Button {
                                moveHomeCard(configuration.id, by: -1)
                            } label: {
                                Image(systemName: "chevron.up.circle.fill")
                                    .font(.title3.weight(.semibold))
                            }
                            .disabled(isFirstHomeCard(configuration.id))

                            Button {
                                moveHomeCard(configuration.id, by: 1)
                            } label: {
                                Image(systemName: "chevron.down.circle.fill")
                                    .font(.title3.weight(.semibold))
                            }
                            .disabled(isLastHomeCard(configuration.id))

                            if configuration.id.supportsResizing {
                                Menu {
                                    Picker("Size", selection: sizeBinding(for: configuration.id)) {
                                        ForEach(HomeScreenCardSize.allCases) { size in
                                            Text(size.title).tag(size)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                                        .font(.title3.weight(.semibold))
                                }
                            }
                        }
                        .foregroundStyle(backgroundTheme.glowColor)
                        .padding(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .contentShape(Rectangle())
        .onDrag {
            guard isCustomizingHome else {
                return NSItemProvider()
            }

            draggingHomeCardID = configuration.id
            return NSItemProvider(object: configuration.id.rawValue as NSString)
        }
        .onLongPressGesture {
            guard !isCustomizingHome else { return }
            isCustomizingHome = true
        }
    }

    var addCardsArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !homeScreenLayout.availableCards.isEmpty {
                Text("Add widgets")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 2)

                VStack(spacing: 8) {
                    ForEach(homeScreenLayout.availableCards) { cardID in
                        Button {
                            addHomeCard(cardID)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: cardID.systemImage)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(backgroundTheme.glowColor)
                                    .frame(width: 36, height: 36)
                                    .background(backgroundTheme.glowColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cardID.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Text(cardID.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.78)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "plus.circle.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(backgroundTheme.glowColor)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.primary.opacity(0.07))
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var addWidgetToolbarMenu: some View {
        Menu {
            if homeScreenLayout.availableCards.isEmpty {
                Text("No widgets available")
            } else {
                ForEach(homeScreenLayout.availableCards) { cardID in
                    Button {
                        addHomeCard(cardID)
                    } label: {
                        Label(cardID.title, systemImage: cardID.systemImage)
                    }
                }
            }
        } label: {
            Label("Add Widget", systemImage: "widget.small.badge.plus")
        }
    }

    func updateHomeLayout(_ update: (inout HomeScreenLayout) -> Void) {
        var layout = homeScreenLayout
        update(&layout)
        homeScreenLayoutData = layout.normalized().encoded()
    }

    func addHomeCard(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            layout.cards.insert(HomeScreenCardConfiguration(id: id, size: id.supportsResizing ? .compact : .standard), at: 0)
        }
    }

    func removeHomeCard(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            layout.cards.removeAll { $0.id == id }
        }
    }

    func moveHomeCard(_ id: HomeScreenCardID, by offset: Int) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == id }) else {
                return
            }

            let destinationIndex = min(max(sourceIndex + offset, 0), layout.cards.count - 1)
            guard sourceIndex != destinationIndex else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            layout.cards.insert(card, at: destinationIndex)
        }
    }

    func moveHomeCard(_ sourceID: HomeScreenCardID, relativeTo destinationID: HomeScreenCardID, insertAfter: Bool) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == sourceID }),
                  let destinationIndex = layout.cards.firstIndex(where: { $0.id == destinationID }) else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            let adjustedDestinationIndex: Int

            if insertAfter {
                adjustedDestinationIndex = sourceIndex < destinationIndex ? destinationIndex : destinationIndex + 1
            } else {
                adjustedDestinationIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
            }

            layout.cards.insert(card, at: adjustedDestinationIndex)
        }
    }

    func moveHomeCard(_ sourceID: HomeScreenCardID, toGridLocation location: CGPoint) {
        if let target = dropTarget(at: location, excluding: sourceID) {
            moveHomeCard(sourceID, relativeTo: target.id, insertAfter: target.insertAfter)
        } else {
            moveHomeCardToEnd(sourceID)
        }
    }

    func moveHomeCardToEnd(_ id: HomeScreenCardID) {
        updateHomeLayout { layout in
            guard let sourceIndex = layout.cards.firstIndex(where: { $0.id == id }),
                  sourceIndex != layout.cards.count - 1 else {
                return
            }

            let card = layout.cards.remove(at: sourceIndex)
            layout.cards.append(card)
        }
    }

    func dropTarget(at location: CGPoint, excluding sourceID: HomeScreenCardID) -> (id: HomeScreenCardID, insertAfter: Bool)? {
        guard homeGridWidth > 0 else { return nil }

        let cards = homeScreenLayout.cards.filter { $0.id != sourceID }
        let placements = HomeScreenGridLayout.gridPlacements(for: cards)
        let columnWidth = max(0, (homeGridWidth - HomeScreenGridLayout.defaultHorizontalSpacing * 3) / 4)
        let rowHeight = columnWidth

        for placement in placements {
            let rect = CGRect(
                x: CGFloat(placement.x) * (columnWidth + HomeScreenGridLayout.defaultHorizontalSpacing),
                y: CGFloat(placement.y) * (rowHeight + HomeScreenGridLayout.defaultVerticalSpacing),
                width: columnWidth * CGFloat(placement.width) + HomeScreenGridLayout.defaultHorizontalSpacing * CGFloat(placement.width - 1),
                height: rowHeight * CGFloat(placement.height) + HomeScreenGridLayout.defaultVerticalSpacing * CGFloat(placement.height - 1)
            )

            if rect.contains(location) {
                let insertAfter = location.y > rect.midY || location.x > rect.midX
                return (cards[placement.index].id, insertAfter)
            }
        }

        return placements.first { placement in
            let centerY = CGFloat(placement.y) * (rowHeight + HomeScreenGridLayout.defaultVerticalSpacing) + rowHeight * CGFloat(placement.height) / 2
            let centerX = CGFloat(placement.x) * (columnWidth + HomeScreenGridLayout.defaultHorizontalSpacing) + columnWidth * CGFloat(placement.width) / 2
            return location.y < centerY || (abs(location.y - centerY) < rowHeight / 2 && location.x < centerX)
        }.map { (cards[$0.index].id, false) }
    }

    func isFirstHomeCard(_ id: HomeScreenCardID) -> Bool {
        homeScreenLayout.cards.first?.id == id
    }

    func isLastHomeCard(_ id: HomeScreenCardID) -> Bool {
        homeScreenLayout.cards.last?.id == id
    }

    func sizeBinding(for id: HomeScreenCardID) -> Binding<HomeScreenCardSize> {
        Binding {
            homeScreenLayout.cards.first(where: { $0.id == id })?.size ?? .standard
        } set: { newSize in
            updateHomeLayout { layout in
                guard let index = layout.cards.firstIndex(where: { $0.id == id }) else {
                    return
                }

                layout.cards[index].size = newSize
            }
        }
    }
}
