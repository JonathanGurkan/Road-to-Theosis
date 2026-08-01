import SwiftUI

struct AppBackgroundView: View {
    let theme: AppBackgroundTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    backgroundColors[0],
                    backgroundColors[1],
                    backgroundColors[2]
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [glowColor.opacity(colorScheme == .dark ? 0.18 : 0.09), .clear],
                center: .topTrailing,
                startRadius: 24,
                endRadius: colorScheme == .dark ? 420 : 520
            )
            .blendMode(colorScheme == .dark ? .screen : .plusLighter)
            .blur(radius: colorScheme == .dark ? 8 : 6)
            .offset(x: 84, y: colorScheme == .dark ? -116 : -96)

            RadialGradient(
                colors: [secondaryGlowColor.opacity(colorScheme == .dark ? 0.08 : 0.05), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: colorScheme == .dark ? 360 : 440
            )
            .blendMode(colorScheme == .dark ? .overlay : .softLight)
            .blur(radius: colorScheme == .dark ? 18 : 12)
            .offset(x: -92, y: colorScheme == .dark ? 118 : 104)

            LinearGradient(
                colors: [.clear, dividerGlowColor.opacity(colorScheme == .dark ? 0.04 : 0.03), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(colorScheme == .dark ? .softLight : .multiply)
            .padding(.horizontal, -40)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return theme.colors.map { $0.opacity(0.96) }
        }

        return theme.lightColors
    }

    private var glowColor: Color {
        colorScheme == .dark ? theme.glowColor : theme.glowColor.opacity(0.88)
    }

    private var secondaryGlowColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var dividerGlowColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

#Preview {
    AppBackgroundView(theme: .blood)
}
