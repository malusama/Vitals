import SwiftUI

struct GPUCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    let gpu: GPUMetrics

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 8 * textScale) {
                MetricSectionHeader(
                    title: "GPU", icon: "display", color: MetricAccentColor.purple(for: colorScheme),
                    value: gpu.utilization.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—"
                )
                if let utilization = gpu.utilization {
                    UsageBarView(value: utilization, color: MetricAccentColor.purple(for: colorScheme), height: 4)
                        .accessibilityHidden(true)
                }
                if let used = gpu.vramUsed {
                    MetricValueRow(title: "GPU memory", value: memoryValue(used))
                }
                if let temperature = gpu.temperature {
                    MetricValueRow(
                        title: "Temperature", value: String(format: "%.0f°C", temperature), icon: "thermometer.medium")
                }
                if gpu.utilization == nil && gpu.vramUsed == nil && gpu.temperature == nil {
                    Text("GPU readings unavailable").scaledFont(10).adaptiveSecondary()
                }
            }
        }
    }

    private func memoryValue(_ used: UInt64) -> String {
        if let total = gpu.vramTotal, total > 0 {
            return "\(Formatters.formatBytes(used)) / \(Formatters.formatBytes(total))"
        }
        return Formatters.formatBytes(used)
    }
}
