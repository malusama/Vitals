import SwiftUI

struct MetricSectionHeader: View {
    @Environment(\.textScale) private var textScale

    let title: LocalizedStringKey
    let icon: String
    let color: Color
    var value: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(color)
                .frame(width: 14 * textScale)
                .accessibilityHidden(true)
            Text(title)
                .scaledFont(12, weight: .semibold, design: .rounded)
            Spacer(minLength: 6)
            if let value {
                Text(value)
                    .scaledFont(12, weight: .semibold, design: .rounded)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
    }
}
