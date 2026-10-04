import SwiftUI

struct WiFiCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    let wifi: WiFiMetrics

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 8 * textScale) {
                MetricSectionHeader(
                    title: "Wi-Fi", icon: wifi.ssid == nil ? "wifi.slash" : "wifi",
                    color: MetricAccentColor.blue(for: colorScheme))
                if let ssid = wifi.ssid {
                    Text(ssid).scaledFont(11, weight: .medium).foregroundStyle(.primary).lineLimit(2).truncationMode(
                        .middle
                    ).help(ssid)
                    if wifi.rssi != nil {
                        UsageBarView(value: wifi.signalQuality, color: signalColor, height: 4).accessibilityHidden(true)
                    }
                    if wifi.rssi != nil || wifi.txRate != nil {
                        VStack(spacing: 6 * textScale) {
                            if let rssi = wifi.rssi {
                                MetricValueRow(title: "Signal", value: "\(rssi) dBm")
                            }
                            if let rate = wifi.txRate {
                                MetricValueRow(title: "Link", value: "\(rate) Mbps")
                            }
                        }
                    }
                    if let channel = wifi.channel {
                        MetricValueRow(title: "Channel", value: channel)
                    }
                    if wifi.localIP != nil || wifi.publicIP != nil {
                        Divider().opacity(0.4)
                        VStack(alignment: .leading, spacing: 6 * textScale) {
                            if let localIP = wifi.localIP { addressRow("Local IP", value: localIP) }
                            if let publicIP = wifi.publicIP { addressRow("Public IP", value: publicIP) }
                        }
                    }
                } else {
                    Text("Not Connected").scaledFont(10).adaptiveSecondary()
                }
            }
        }
    }

    private var signalColor: Color {
        if wifi.signalQuality > 0.7 { return MetricAccentColor.blue(for: colorScheme) }
        if wifi.signalQuality > 0.4 { return MetricAccentColor.orange(for: colorScheme) }
        return MetricAccentColor.red(for: colorScheme)
    }

    private func addressRow(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3 * textScale) {
            Text(title).scaledFont(9).adaptiveSecondary()
            Text(value)
                .scaledFont(10, weight: .medium, design: .monospaced)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .help(value)
        }
        .accessibilityElement(children: .combine)
    }
}
