import SwiftUI

struct ActionButtonView: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(colorScheme == .dark ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background {
                let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
                if #available(iOS 26.0, *) {
                    shape.fill(tint.opacity(colorScheme == .dark ? 0.08 : 0.12))
                        .glassEffect(.regular, in: shape)
                } else {
                    shape.fill(tint.opacity(colorScheme == .dark ? 0.14 : 0.12))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
