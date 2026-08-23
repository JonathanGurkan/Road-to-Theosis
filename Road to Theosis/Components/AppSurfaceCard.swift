import SwiftUI

struct AppSurfaceCard<Content: View>: View {
    private let content: Content
    private let contentPadding: CGFloat
    private let fillsAvailableHeight: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(contentPadding: CGFloat = 16, fillsAvailableHeight: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.contentPadding = contentPadding
        self.fillsAvailableHeight = fillsAvailableHeight
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        content
            .frame(
                maxWidth: .infinity,
                maxHeight: fillsAvailableHeight ? .infinity : nil,
                alignment: .leading
            )
            .padding(contentPadding)
            .background {
                shape.fill(cardFillColor)
            }
            .overlay(
                shape.strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.08 : 0.04), radius: colorScheme == .dark ? 7 : 5, x: 0, y: colorScheme == .dark ? 4 : 2)
    }

    private var cardFillColor: Color {
        Color(uiColor: colorScheme == .dark ? .secondarySystemBackground : .systemBackground)
            .opacity(colorScheme == .dark ? 0.82 : 0.94)
    }
}

#Preview {
    AppSurfaceCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Surface card")
                .font(.headline.weight(.semibold))

            Text("Reusable app card styling.")
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}

extension View {
    @ViewBuilder
    func ifAvailableGlassProminent(tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.buttonStyle(.glassProminent)
                    .tint(tint)
            } else {
                self.buttonStyle(.glassProminent)
            }
        } else {
            if let tint {
                self.buttonStyle(.borderedProminent)
                    .tint(tint)
            } else {
                self.buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    func ifAvailableGlass(tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.buttonStyle(.glass)
                    .tint(tint)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if let tint {
                self.buttonStyle(.bordered)
                    .tint(tint)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }
}
