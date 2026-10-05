import SwiftUI

struct DiskCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.metricCardPresentation) private var presentation

    let disk: DiskMetrics
    let temperature: Double?

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: presentation.spacing(8, textScale: textScale)) {
                MetricSectionHeader(title: "Disk", icon: "internaldrive.fill", color: MetricAccentColor.blue(for: colorScheme), value: usedPercentage)

                UsageBarView(value: disk.usageRatio, color: capacityColor, height: 4)
                    .accessibilityHidden(true)

                HStack(spacing: 6) {
                    Text("Used")
                    Spacer(minLength: 0)
                    Text("\(Formatters.formatBytes(disk.usedSpace)) / \(Formatters.formatBytes(disk.totalSpace))")
                        .monospacedDigit()
                        .fixedSize()
                }
                .scaledFont(9)
                .adaptiveSecondary()
                .accessibilityElement(children: .combine)

                VStack(spacing: presentation.spacing(6, textScale: textScale)) {
                    transferRow("Read", icon: "arrow.down.doc", speed: disk.readSpeed)
                    transferRow("Write", icon: "arrow.up.doc", speed: disk.writeSpeed)
                }

                Divider().opacity(0.4)
                HStack(spacing: 5) {
                    Text("Free")
                    Text(Formatters.formatBytes(disk.freeSpace))
                        .fontWeight(.medium)
                    Spacer(minLength: 0)
                    if let temperature {
                        Image(systemName: "thermometer.medium")
                        Text(String(format: "%.0f°C", temperature))
                    }
                }
                .scaledFont(9)
                .monospacedDigit()
                .adaptiveSecondary()
                .lineLimit(1)
            }
        }
    }

    private var usedPercentage: String {
        disk.usageRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    private var capacityColor: Color {
        if disk.usageRatio >= 0.95 { return MetricAccentColor.red(for: colorScheme) }
        if disk.usageRatio >= 0.9 { return MetricAccentColor.orange(for: colorScheme) }
        return MetricAccentColor.blue(for: colorScheme)
    }

    private func transferRow(_ title: LocalizedStringKey, icon: String, speed: UInt64) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 12 * textScale)
                .scaledFont(10)
                .adaptiveSecondary()
            Text(title)
                .scaledFont(10)
                .adaptiveSecondary()
            Spacer(minLength: 6)
            Text(Formatters.formatBytesPerSec(speed))
                .scaledFont(12, weight: .semibold, design: .rounded)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}
