import SwiftUI

struct MemoryCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.metricCardPresentation) private var presentation
    let memory: MemoryMetrics

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: presentation.spacing(8, textScale: textScale)) {
                MetricSectionHeader(
                    title: "Memory", icon: "memorychip.fill", color: MetricAccentColor.teal(for: colorScheme),
                    value: memory.total > 0 ? memory.usageRatio.formatted(.percent.precision(.fractionLength(0))) : "—"
                )
                if memory.total > 0 {
                    UsageBarView(value: memory.usageRatio, color: pressureColor, height: 4).accessibilityHidden(true)
                    HStack(spacing: 6) {
                        Text("Used")
                        Spacer(minLength: 0)
                        Text("\(Formatters.formatBytes(memory.used)) / \(Formatters.formatBytes(memory.total))")
                            .monospacedDigit().fixedSize()
                    }
                    .scaledFont(9).adaptiveSecondary().accessibilityElement(children: .combine)

                    VStack(spacing: presentation.spacing(6, textScale: textScale)) {
                        MetricValueRow(title: "Active", value: Formatters.formatBytes(memory.active))
                        MetricValueRow(title: "Wired", value: Formatters.formatBytes(memory.wired))
                        MetricValueRow(title: "Compressed", value: Formatters.formatBytes(memory.compressed))
                    }
                    Divider().opacity(0.4)
                    HStack(spacing: 4) {
                        Text("Free")
                        Text(Formatters.formatBytes(memory.free)).fontWeight(.medium).monospacedDigit()
                        Spacer(minLength: 6)
                        Text("Pressure")
                        Circle().fill(pressureColor).frame(width: 5, height: 5).accessibilityHidden(true)
                        Text(pressureLabel).fontWeight(.medium)
                    }
                    .scaledFont(9).adaptiveSecondary().lineLimit(1).accessibilityElement(children: .combine)
                } else {
                    Text("Memory readings unavailable").scaledFont(10).adaptiveSecondary()
                }
            }
        }
    }

    private var pressureLabel: LocalizedStringKey {
        switch memory.pressure {
        case .nominal: "Normal"
        case .warning: "Elevated"
        case .critical: "High"
        }
    }

    private var pressureColor: Color {
        switch memory.pressure {
        case .nominal: MetricAccentColor.teal(for: colorScheme)
        case .warning: MetricAccentColor.orange(for: colorScheme)
        case .critical: MetricAccentColor.red(for: colorScheme)
        }
    }
}
