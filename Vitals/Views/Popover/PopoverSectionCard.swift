import SwiftUI

/// The full readings stay visible in a narrow card, without disclosure state.
struct PopoverSectionCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.textScale) private var textScale
    let section: PopoverSection
    @Binding var processMetric: ProcessMetric

    private var metrics: SystemMetrics { appState.metrics }

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 4 * textScale) {
                MetricSectionHeader(
                    title: LocalizedStringKey(section.label), icon: icon, color: accent, value: value)
                    .frame(minHeight: 18)
                details.environment(\.metricCardPresentation, .details)
            }
        }
        .environment(\.metricCardPresentation, .compact)
        .accessibilityElement(children: .contain)
        .task {
            guard section == .processes else { return }
            // Only scan while the enabled processes section is on screen.
            while !Task.isCancelled {
                if appState.isPopoverVisible { await appState.refreshTopProcesses() }
                try? await Task.sleep(for: .seconds(3))
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

    private func percentage(_ ratio: Double) -> String {
        ratio.formatted(.percent.precision(.fractionLength(0)))
    }
}
