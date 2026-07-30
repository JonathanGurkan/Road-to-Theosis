import SwiftUI

struct AppSurfaceCard<Content: View>: View {
    private let content: Content
    private let contentPadding: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    init(contentPadding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.contentPadding = contentPadding
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(contentPadding)
            .background {
                if colorScheme == .dark {
                    if #available(iOS 26.0, *) {
                        shape.fill(.clear)
                            .glassEffect(.regular, in: shape)
                    } else {
                        shape.fill(.ultraThinMaterial)
                    }
                } else {
                    shape.fill(Color(uiColor: .secondarySystemBackground).opacity(0.92))
                }
            }
            .overlay(
                shape.strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.05), radius: colorScheme == .dark ? 14 : 10, x: 0, y: colorScheme == .dark ? 8 : 4)
    }
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
