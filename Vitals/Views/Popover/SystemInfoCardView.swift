import SwiftUI

struct SystemInfoCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    let info: SystemInfoMetrics

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 8 * textScale) {
                MetricSectionHeader(
                    title: "System", icon: "desktopcomputer", color: MetricAccentColor.blue(for: colorScheme))
                if !info.modelName.isEmpty {
                    Text(info.modelName).scaledFont(11, weight: .medium).foregroundStyle(.primary).lineLimit(2).help(
                        info.modelName)
                }
                if !info.osVersion.isEmpty {
                    VStack(spacing: 6 * textScale) {
                        MetricValueRow(title: "User", value: info.username, icon: "person", allowsWrapping: true)
                        MetricValueRow(
                            title: "Computer", value: info.hostname, icon: "laptopcomputer", allowsWrapping: true)
                        MetricValueRow(title: "Version", value: info.osVersion, icon: "gearshape", allowsWrapping: true)
                        MetricValueRow(title: "Uptime", value: info.formattedUptime, icon: "clock")
                    }
                } else {
                    Text("System readings unavailable").scaledFont(10).adaptiveSecondary()
                }
            }
        }
    }
}
