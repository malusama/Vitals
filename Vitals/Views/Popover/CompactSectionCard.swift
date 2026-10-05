import SwiftUI

/// A narrow overview stays visible; the original detailed cards render inline
/// when expanded, sharing the same glass surface and metric snapshot.
struct CompactSectionCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.textScale) private var textScale
    let section: PopoverSection
    @Binding var isExpanded: Bool
    @Binding var processMetric: ProcessMetric

    private var metrics: SystemMetrics { appState.metrics }

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 6 * textScale) {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 6) {
                        MetricSectionHeader(
                            title: LocalizedStringKey(section.label), icon: icon, color: accent, value: value)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .scaledFont(8, weight: .semibold)
                            .adaptiveSecondary()
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(isExpanded ? String(localized: "Expanded") : String(localized: "Collapsed"))
                .help(isExpanded ? String(localized: "Hide details") : String(localized: "Show details"))

                if isExpanded {
                    details.environment(\.metricCardPresentation, .details)
                } else {
                    summary
                }
            }
        }
        .environment(\.metricCardPresentation, .compact)
        .accessibilityElement(children: .contain)
        .task {
            guard section == .processes else { return }
            // The summary needs the leading process too. Scan only while this
            // enabled section is on screen, regardless of expansion state.
            while !Task.isCancelled {
                if appState.isPopoverVisible { await appState.refreshTopProcesses() }
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    @ViewBuilder
    private var summary: some View {
        switch section {
        case .cpu:
            VStack(spacing: 4 * textScale) {
                if metrics.thermal.cpuTemperature != nil || metrics.thermal.fanRPM != nil {
                    HStack {
                        if let temperature = metrics.thermal.cpuTemperature {
                            sensor(
                                "CPU temperature", icon: "thermometer.medium",
                                value: String(format: "%.0f°C", temperature))
                        }
                        Spacer(minLength: 6)
                        if let rpm = metrics.thermal.fanRPM {
                            sensor("Fan", icon: "fan", value: rpm > 0 ? "\(rpm) RPM" : String(localized: "Off"))
                        }
                    }
                }
                if let watts = metrics.thermal.systemPower {
                    reading("System power", Formatters.formatWatts(watts))
                }
                if metrics.cpu.totalCores == 0 { unavailable("CPU readings unavailable") }
            }
        case .gpu:
            HStack {
                if let used = metrics.gpu.vramUsed {
                    Text("Memory").scaledFont(9).adaptiveSecondary()
                    Text(Formatters.formatBytes(used)).scaledFont(11, weight: .medium).monospacedDigit()
                }
                Spacer(minLength: 6)
                if let temperature = metrics.gpu.temperature {
                    sensor("GPU temperature", icon: "thermometer.medium", value: String(format: "%.0f°C", temperature))
                }
                if metrics.gpu.vramUsed == nil && metrics.gpu.temperature == nil {
                    unavailable("GPU readings unavailable")
                }
            }
        case .memory:
            if metrics.memory.total > 0 {
                VStack(spacing: 4 * textScale) {
                    reading(
                        "Used",
                        "\(Formatters.formatBytes(metrics.memory.used)) / \(Formatters.formatBytes(metrics.memory.total))"
                    )
                    HStack(spacing: 4) {
                        Text("Free")
                        Text(Formatters.formatBytes(metrics.memory.free)).monospacedDigit()
                        Spacer(minLength: 6)
                        Circle().fill(memoryPressureColor).frame(width: 5, height: 5).accessibilityHidden(true)
                        Text(memoryPressureLabel)
                    }
                    .scaledFont(9).adaptiveSecondary().lineLimit(1)
                    .accessibilityElement(children: .combine)
                    .help(String(localized: "Memory pressure"))
                }
            } else {
                unavailable("Memory readings unavailable")
            }
        case .battery:
            if let battery = metrics.battery {
                VStack(spacing: 4 * textScale) {
                    HStack(spacing: 4) {
                        Text(battery.statusLabel).scaledFont(9, weight: .medium)
                        Spacer(minLength: 4)
                        if let time = battery.timeRemaining, time > 0 {
                            Text(
                                battery.isCharging
                                    ? String(localized: "\(Formatters.formatDuration(time)) to full")
                                    : String(localized: "\(Formatters.formatDuration(time)) left")
                            )
                            .scaledFont(9).monospacedDigit().adaptiveSecondary().fixedSize()
                        }
                    }
                    reading("Adapter input", Formatters.formatWatts(battery.adapterPowerWatts))
                        .help(adapterHelp(battery))
                    reading(
                        batteryPowerLabel(battery), Formatters.formatWatts(battery.batteryPowerWatts.map { abs($0) }),
                        color: battery.isDischarging && battery.isPluggedIn
                            ? MetricAccentColor.orange(for: colorScheme) : .primary)
                }
            }
        case .disk:
            if metrics.disk.totalSpace > 0 {
                VStack(spacing: 4 * textScale) {
                    HStack(spacing: 4) {
                        Text("Free").scaledFont(9).adaptiveSecondary()
                        Text(Formatters.formatBytes(metrics.disk.freeSpace)).scaledFont(11, weight: .medium)
                            .monospacedDigit()
                        Spacer(minLength: 4)
                        if let temperature = metrics.thermal.ssdTemperature {
                            sensor(
                                "Disk temperature", icon: "thermometer.medium",
                                value: String(format: "%.0f°C", temperature))
                        }
                    }
                    HStack(spacing: 12) {
                        transfer("Read", icon: "arrow.down.doc", speed: metrics.disk.readSpeed, color: accent)
                        transfer("Write", icon: "arrow.up.doc", speed: metrics.disk.writeSpeed, color: accent)
                    }
                }
            } else {
                unavailable("Disk readings unavailable")
            }
        case .network:
            HStack(spacing: 12) {
                transfer(
                    "Download", icon: "arrow.down", speed: metrics.network.downloadSpeed,
                    color: MetricAccentColor.blue(for: colorScheme))
                transfer(
                    "Upload", icon: "arrow.up", speed: metrics.network.uploadSpeed,
                    color: MetricAccentColor.purple(for: colorScheme))
            }
        case .system:
            if !metrics.systemInfo.modelName.isEmpty {
                VStack(alignment: .leading, spacing: 4 * textScale) {
                    Text(metrics.systemInfo.modelName).scaledFont(10, weight: .medium).lineLimit(1)
                        .truncationMode(.middle).help(metrics.systemInfo.modelName)
                    reading("Uptime", metrics.systemInfo.formattedUptime)
                }
            } else {
                unavailable("System information unavailable")
            }
        case .wifi:
            if let ssid = metrics.wifi.ssid {
                VStack(alignment: .leading, spacing: 4 * textScale) {
                    Text(ssid).scaledFont(10, weight: .medium).lineLimit(1).truncationMode(.middle).help(ssid)
                    HStack {
                        if let rssi = metrics.wifi.rssi {
                            sensor("Signal", icon: "wifi", value: "\(rssi) dBm")
                        }
                        Spacer(minLength: 4)
                        if let rate = metrics.wifi.txRate {
                            Text("\(rate) Mbps").scaledFont(9).monospacedDigit().adaptiveSecondary()
                        }
                    }
                }
            } else {
                unavailable("Not Connected")
            }
        case .processes:
            if let process = leadingProcess {
                Text(process.name).scaledFont(10).lineLimit(1).truncationMode(.middle)
                    .help("\(process.name) · PID \(process.id)")
            } else {
                unavailable("Gathering…")
            }
        }
    }

    @ViewBuilder
    private var details: some View {
        switch section {
        case .cpu: CPUDetailView()
        case .gpu: GPUDetailView()
        case .memory: MemoryDetailView()
        case .battery: BatteryDetailView()
        case .disk: DiskDetailView()
        case .network: NetworkDetailView()
        case .system: SystemInfoDetailView()
        case .wifi: WiFiDetailView()
        case .processes:
            TopProcessesCardView(
                byCPU: appState.topProcessesByCPU, byMemory: appState.topProcessesByMemory, metric: $processMetric)
        }
    }

    private var value: String? {
        switch section {
        case .cpu: metrics.cpu.totalCores > 0 ? percentage(metrics.cpu.totalUsage) : "—"
        case .gpu: metrics.gpu.utilization.map(percentage) ?? "—"
        case .memory: metrics.memory.total > 0 ? percentage(metrics.memory.usageRatio) : "—"
        case .battery: metrics.battery.map { "\($0.percentage)%" }
        case .disk: metrics.disk.totalSpace > 0 ? percentage(metrics.disk.usageRatio) : "—"
        case .system: metrics.systemInfo.osVersion.isEmpty ? nil : metrics.systemInfo.osVersion
        case .processes:
            leadingProcess.map {
                processMetric == .cpu
                    ? Formatters.formatCPUPercent($0.cpuPercent) : Formatters.formatBytes($0.memoryBytes)
            }
        case .network, .wifi: nil
        }
    }

    private var icon: String {
        switch section {
        case .cpu: "cpu.fill"
        case .gpu: "display"
        case .memory: "memorychip.fill"
        case .battery: batteryIcon
        case .disk: "internaldrive.fill"
        case .network: "network"
        case .system: "desktopcomputer"
        case .wifi: metrics.wifi.ssid == nil ? "wifi.slash" : "wifi"
        case .processes: "list.bullet.rectangle"
        }
    }

    private var accent: Color {
        switch section {
        case .gpu: MetricAccentColor.purple(for: colorScheme)
        case .memory: MetricAccentColor.teal(for: colorScheme)
        case .battery: MetricAccentColor.green(for: colorScheme)
        case .processes: MetricAccentColor.orange(for: colorScheme)
        default: MetricAccentColor.blue(for: colorScheme)
        }
    }

    private var leadingProcess: ProcessUsage? {
        (processMetric == .cpu ? appState.topProcessesByCPU : appState.topProcessesByMemory).first
    }

    private var batteryIcon: String {
        guard let battery = metrics.battery else { return "battery.0percent" }
        if battery.isCharging { return "battery.100percent.bolt" }
        switch battery.percentage {
        case 0..<13: return "battery.0percent"
        case 13..<38: return "battery.25percent"
        case 38..<63: return "battery.50percent"
        case 63..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    private var memoryPressureLabel: LocalizedStringKey {
        switch metrics.memory.pressure {
        case .nominal: "Normal"
        case .warning: "Elevated"
        case .critical: "High"
        }
    }

    private var memoryPressureColor: Color {
        switch metrics.memory.pressure {
        case .nominal: MetricAccentColor.teal(for: colorScheme)
        case .warning: MetricAccentColor.orange(for: colorScheme)
        case .critical: MetricAccentColor.red(for: colorScheme)
        }
    }

    private func batteryPowerLabel(_ battery: BatteryMetrics) -> LocalizedStringKey {
        if battery.isDischarging { return "Battery output" }
        if battery.isCharging { return "Battery charging" }
        return battery.batteryPowerWatts == nil ? "Battery" : "Battery idle"
    }

    private func adapterHelp(_ battery: BatteryMetrics) -> String {
        guard let limit = battery.adapterMaxPowerWatts else { return String(localized: "Measured adapter input.") }
        return String(localized: "Measured adapter input. Negotiated limit:") + " " + Formatters.formatWatts(limit)
    }

    private func reading(_ title: LocalizedStringKey, _ value: String, color: Color = .primary) -> some View {
        HStack(spacing: 6) {
            Text(title).scaledFont(9).adaptiveSecondary()
            Spacer(minLength: 4)
            Text(value).scaledFont(11, weight: .semibold, design: .rounded).monospacedDigit()
                .foregroundStyle(color).fixedSize()
        }
        .accessibilityElement(children: .combine)
    }

    private func sensor(_ title: LocalizedStringKey, icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).accessibilityHidden(true)
            Text(value).monospacedDigit()
        }
        .scaledFont(9).adaptiveSecondary()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(Text(title)): \(value)"))
    }

    private func transfer(_ title: LocalizedStringKey, icon: String, speed: UInt64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2 * textScale) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(color).accessibilityHidden(true)
                Text(title).adaptiveSecondary()
            }
            .scaledFont(9)
            Text(Formatters.formatBytesPerSec(speed)).scaledFont(11, weight: .semibold, design: .rounded)
                .monospacedDigit().fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func unavailable(_ title: LocalizedStringKey) -> some View {
        Text(title).scaledFont(9).adaptiveSecondary()
    }

    private func percentage(_ ratio: Double) -> String {
        ratio.formatted(.percent.precision(.fractionLength(0)))
    }
}
