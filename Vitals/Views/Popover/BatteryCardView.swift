import SwiftUI

struct BatteryCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme

    let battery: BatteryMetrics
    let temperature: Double?
    let history: MetricHistory

    var body: some View {
        MetricCardView(
            metricType: .battery,
            icon: batteryIcon,
            title: "Battery",
            value: "\(battery.percentage)%",
            color: batteryColor,
            history: history,
            showsHistory: false
        ) {
            VStack(alignment: .leading, spacing: 8 * textScale) {
                UsageBarView(value: Double(battery.percentage) / 100, color: batteryColor, height: 4)
                    .accessibilityHidden(true)

                HStack(spacing: 8) {
                    Text(status)
                        .scaledFont(10, weight: .medium)
                    Spacer(minLength: 0)
                    if let time = battery.timeRemaining, time > 0 {
                        Text(battery.isCharging
                             ? String(localized: "\(Formatters.formatDuration(time)) to full")
                             : String(localized: "\(Formatters.formatDuration(time)) left"))
                            .scaledFont(9)
                            .monospacedDigit()
                            .adaptiveSecondary()
                            .fixedSize()
                    }
                }
                .lineLimit(1)

                VStack(spacing: 6 * textScale) {
                    powerRow("Adapter input", icon: "powerplug.fill", watts: battery.adapterPowerWatts)
                        .help(adapterHelp)
                    powerRow(batteryPowerLabel, icon: batteryPowerIcon, watts: battery.batteryPowerWatts.map { abs($0) }, emphasized: battery.isDischarging && battery.isPluggedIn)
                }

                if battery.healthPercent != nil || battery.cycleCount != nil || temperature != nil {
                    Divider().opacity(0.4)
                    HStack(spacing: 5) {
                        if let health = battery.healthPercent {
                            Text("Health")
                            Text("\(health)%")
                                .fontWeight(.medium)
                        }
                        if let cycles = battery.cycleCount {
                            if battery.healthPercent != nil { Text("·") }
                            Text("\(cycles) cycles")
                        }
                        Spacer(minLength: 0)
                        if let temperature {
                            Image(systemName: "thermometer.medium")
                            Text(String(format: "%.1f°C", temperature))
                        }
                    }
                    .scaledFont(9)
                    .monospacedDigit()
                    .adaptiveSecondary()
                    .lineLimit(1)
                }
            }
        }
    }

    private var status: String {
        battery.isDischarging && battery.isPluggedIn
            ? String(localized: "Discharging on AC") : battery.statusLabel
    }

    private var batteryPowerLabel: LocalizedStringKey {
        if battery.isDischarging { return "Battery output" }
        if battery.isCharging { return "Battery charging" }
        return battery.batteryPowerWatts == nil ? "Battery" : "Battery idle"
    }

    private var batteryPowerIcon: String {
        if battery.isDischarging { return "arrow.up.right" }
        if battery.isCharging { return "arrow.down.left" }
        return battery.batteryPowerWatts == nil ? "battery.75percent" : "minus"
    }

    private var adapterHelp: String {
        if let limit = battery.adapterMaxPowerWatts {
            return String(localized: "Measured adapter input. Negotiated limit:") + " " + Formatters.formatWatts(limit)
        }
        return String(localized: "Measured adapter input.")
    }

    private var batteryIcon: String {
        if battery.isCharging { return "battery.100percent.bolt" }
        switch battery.percentage {
        case 0..<13: return "battery.0percent"
        case 13..<38: return "battery.25percent"
        case 38..<63: return "battery.50percent"
        case 63..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    private var batteryColor: Color {
        if battery.isCharging { return .green }
        if battery.percentage < 10 { return .red }
        if battery.percentage < 20 { return .orange }
        return .green
    }

    private func powerRow(_ title: LocalizedStringKey, icon: String, watts: Double?, emphasized: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 12 * textScale)
                .scaledFont(10)
                .adaptiveSecondary()
            Text(title)
                .scaledFont(10)
                .adaptiveSecondary()
            Spacer(minLength: 6)
            Text(Formatters.formatWatts(watts))
                .scaledFont(12, weight: .semibold, design: .rounded)
                .monospacedDigit()
                .foregroundStyle(emphasized ? Color.orange : Color.primary)
                .brightness(emphasized && colorScheme == .light ? -0.2 : 0)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}
