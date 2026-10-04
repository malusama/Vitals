import SwiftUI

struct MetricValueRow: View {
    @Environment(\.textScale) private var textScale

    let title: LocalizedStringKey
    let value: String
    var icon: String?
    var allowsWrapping = false

    var body: some View {
        Group {
            if allowsWrapping {
                ViewThatFits(in: .horizontal) {
                    singleLineRow
                    VStack(alignment: .leading, spacing: 3 * textScale) {
                        label
                        Text(value)
                            .scaledFont(11, weight: .medium)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .help(value)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                singleLineRow
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var singleLineRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            label
            Spacer(minLength: 6)
            Text(value)
                .scaledFont(11, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .fixedSize()
                .help(value)
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .scaledFont(10)
                    .frame(width: 12 * textScale)
                    .adaptiveSecondary()
                    .accessibilityHidden(true)
            }
            Text(title).scaledFont(10).adaptiveSecondary().fixedSize()
        }
    }
}
