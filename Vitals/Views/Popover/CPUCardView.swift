import SwiftUI

struct CPUCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.metricCardPresentation) private var presentation
    let cpu: CPUMetrics
    let thermal: ThermalMetrics
    let history: MetricHistory

    var body: some View {
        MetricCardView(
            metricType: .cpu, icon: "cpu.fill", title: "CPU",
            value: cpu.totalCores > 0 ? percentage(cpu.totalUsage) : "—",
            color: MetricAccentColor.blue(for: colorScheme), history: history, showsHistory: cpu.totalCores > 0
        ) {
            if cpu.totalCores > 0 {
                VStack(spacing: presentation.spacing(8, textScale: textScale)) {
                    HStack(spacing: 12) {
                        MetricValueRow(title: "User", value: percentage(cpu.userUsage)).frame(maxWidth: .infinity)
                        MetricValueRow(title: "System", value: percentage(cpu.systemUsage)).frame(maxWidth: .infinity)
                    }
                    HStack {
                        Text("\(cpu.activeCores) / \(cpu.totalCores) cores")
                        Spacer(minLength: 6)
                        Text("\(percentage(cpu.idleUsage)) idle")
                    }
                    .scaledFont(9).monospacedDigit().adaptiveSecondary().lineLimit(1)

                    if thermal.cpuTemperature != nil || thermal.fanRPM != nil || thermal.systemPower != nil {
                        Divider().opacity(0.4)
                        VStack(spacing: presentation.spacing(6, textScale: textScale)) {
                            if thermal.cpuTemperature != nil || thermal.fanRPM != nil {
                                HStack(spacing: 12) {
                                    if let temperature = thermal.cpuTemperature {
                                        MetricValueRow(title: "Temp", value: String(format: "%.0f°C", temperature))
                                            .frame(maxWidth: .infinity)
                                    }
                                    if let rpm = thermal.fanRPM {
                                        MetricValueRow(
                                            title: "Fan", value: rpm > 0 ? "\(rpm) RPM" : String(localized: "Off")
                                        ).frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            if let watts = thermal.systemPower {
                                MetricValueRow(
                                    title: "System power", value: Formatters.formatWatts(watts), icon: "bolt")
                            }
                        }
                    }
                }
            } else {
                Text("CPU readings unavailable").scaledFont(10).adaptiveSecondary()
            }
        }
    }

    private func percentage(_ ratio: Double) -> String {
        ratio.formatted(.percent.precision(.fractionLength(0)))
    }
}
