import SwiftUI

struct NetworkCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme

    let network: NetworkMetrics
    let downloadHistory: MetricHistory
    let uploadHistory: MetricHistory

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 10 * textScale) {
                MetricSectionHeader(title: "Network", icon: "network", color: MetricAccentColor.blue(for: colorScheme))

                HStack(alignment: .top, spacing: 12) {
                    transferColumn(
                        "Download", icon: "arrow.down", speed: network.downloadSpeed,
                        total: network.totalDownloaded, history: downloadHistory,
                        color: MetricAccentColor.blue(for: colorScheme)
                    )
                    transferColumn(
                        "Upload", icon: "arrow.up", speed: network.uploadSpeed,
                        total: network.totalUploaded, history: uploadHistory,
                        color: MetricAccentColor.purple(for: colorScheme)
                    )
                }
            }
        }
    }

    /// Both directions share a zero-based scale so their heights stay comparable.
    /// A 1 KB/s floor keeps a completely idle chart stable.
    private var chartUpperBound: Double {
        let recentPeak = max(
            downloadHistory.values.map(\.value).max() ?? 0,
            uploadHistory.values.map(\.value).max() ?? 0,
            Double(network.downloadSpeed), Double(network.uploadSpeed)
        )
        return max(1_024, recentPeak) * 1.15
    }

    private func transferColumn(
        _ title: LocalizedStringKey, icon: String, speed: UInt64,
        total: UInt64, history: MetricHistory, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6 * textScale) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .scaledFont(9, weight: .semibold)
                    .foregroundStyle(color)
                Text(title)
                    .scaledFont(9, weight: .medium)
                    .adaptiveSecondary()
            }

            Text(Formatters.formatBytesPerSec(speed))
                .scaledFont(12, weight: .semibold, design: .rounded)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .fixedSize()

            SparklineView(
                history: history, color: color, upperBound: chartUpperBound,
                lineWidth: 1.6, lineOpacity: 1
            )
                .frame(height: 24)
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Text("Total")
                Text(Formatters.formatBytes(total))
                    .monospacedDigit()
                    .fontWeight(.medium)
            }
            .scaledFont(9)
            .adaptiveSecondary()
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
