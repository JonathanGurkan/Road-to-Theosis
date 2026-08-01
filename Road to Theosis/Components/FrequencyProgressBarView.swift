import SwiftUI

struct FrequencyProgressBarView: View {
    let value: Double
    let tint: Color
    var trackHeight: CGFloat = 8
    var dotSize: CGFloat = 4

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                    .fill(tint.opacity(0.88))
                    .frame(width: max(0, width * CGFloat(clampedValue)), height: trackHeight)

                ForEach(SinFrequencyScale.milestoneProgresses, id: \.self) { milestone in
                    let position = min(max(CGFloat(milestone) * width, dotSize / 2), width - dotSize / 2)

                    Circle()
                        .fill(milestone <= clampedValue ? Color(uiColor: .systemBackground).opacity(0.92) : tint.opacity(0.34))
                        .frame(width: dotSize, height: dotSize)
                        .position(x: position, y: trackHeight / 2)
                }
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 16) {
        FrequencyProgressBarView(value: 0.12, tint: .purple)
        FrequencyProgressBarView(value: 0.54, tint: .blue)
        FrequencyProgressBarView(value: 0.84, tint: .red)
    }
    .padding()
}
