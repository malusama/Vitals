import SwiftUI

struct BatteryDetailView: View {

    @Environment(AppState.self) private var appState

    private var battery: BatteryMetrics? { appState.metrics.battery }

    var body: some View {
        if let bat = battery {
            MetricCardView(
                metricType: .battery,
                icon: batteryIcon(bat),
                title: "Battery",
                value: "\(bat.percentage)%",
                color: batteryColor(bat),
                history: appState.batteryHistory
            ) {
                VStack(spacing: 4) {
                    HStack {
                        miniLabel("Status", bat.statusLabel)
                        Spacer()
                        if let time = bat.timeRemaining, time > 0 {
                            miniLabel(bat.isCharging ? "Full In" : "Remaining", Formatters.formatDuration(time))
                        } else {
                            miniLabel(bat.isCharging ? "Full In" : "Remaining", "—")
                        }
                        Spacer()
                        if let temp = appState.metrics.thermal.batteryTemperature {
                            HStack(spacing: 3) {
                                Image(systemName: "thermometer.medium")
                                Text(String(format: "%.1f°C", temp))
                                    .fontWeight(.medium)
                                    .monospacedDigit()
                            }
                        }
                    }
                    HStack {
                        miniLabel("Adapter In", Formatters.formatWatts(bat.adapterPowerWatts))
                            .help(adapterHelp(bat))
                        Spacer()
                        miniLabel("Battery Charge", Formatters.formatWatts(bat.chargePowerWatts))
                        Spacer()
                        miniLabel("Battery Out", Formatters.formatWatts(bat.dischargePowerWatts))
                    }
                    .padding(.vertical, 3)
                    HStack(spacing: 16) {
                        if let health = bat.healthPercent {
                            miniLabel("Health", "\(health)%")
                        }
                        if let cycles = bat.cycleCount {
                            miniLabel("Cycles", "\(cycles)")
                        }
                        Spacer()
                    }
                }
                .scaledFont(10)
                .adaptiveSecondary()
            }
        }
    }

    private func adapterHelp(_ bat: BatteryMetrics) -> String {
        if let limit = bat.adapterMaxPowerWatts {
            return String(localized: "Measured adapter input. Negotiated limit:") + " " + Formatters.formatWatts(limit)
        }
        return String(localized: "Measured adapter input.")
    }

    private func batteryIcon(_ bat: BatteryMetrics) -> String {
        if bat.isCharging { return "battery.100percent.bolt" }
        switch bat.percentage {
        case 0..<13:  return "battery.0percent"
        case 13..<38: return "battery.25percent"
        case 38..<63: return "battery.50percent"
        case 63..<88: return "battery.75percent"
        default:      return "battery.100percent"
        }
    }

    private func batteryColor(_ bat: BatteryMetrics) -> Color {
        if bat.isCharging { return .green }
        switch bat.percentage {
        case 0..<10:  return .red
        case 10..<20: return .orange
        default:      return .green
        }
    }

    private func miniLabel(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .adaptiveSecondary()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}
