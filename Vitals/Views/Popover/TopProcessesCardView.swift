import SwiftUI

enum ProcessMetric: String, CaseIterable, Identifiable {
    case cpu, memory
    var id: String { rawValue }
    var label: String { self == .cpu ? "CPU" : String(localized: "Memory") }
}

struct TopProcessesCardView: View {
    @Environment(\.textScale) private var textScale
    @Environment(\.colorScheme) private var colorScheme
    let byCPU: [ProcessUsage]
    let byMemory: [ProcessUsage]
    @Binding var metric: ProcessMetric

    private var processes: [ProcessUsage] { metric == .cpu ? byCPU : byMemory }

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 8 * textScale) {
                MetricSectionHeader(
                    title: "Top Processes", icon: "list.bullet.rectangle",
                    color: MetricAccentColor.orange(for: colorScheme))
                Picker("Metric", selection: $metric) {
                    ForEach(ProcessMetric.allCases) { metric in
                        Text(metric.label).tag(metric)
                    }
                }
                .pickerStyle(.segmented).controlSize(.small).labelsHidden()
                if processes.isEmpty {
                    Text("Gathering…").scaledFont(10).adaptiveSecondary().frame(
                        maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        Text("Process")
                        Spacer()
                        Text(metric.label)
                    }
                    .scaledFont(9).adaptiveSecondary()
                    .help(
                        metric == .cpu
                            ? String(localized: "CPU usage relative to one core. Multicore processes can exceed 100%.")
                            : String(localized: "Memory used by each process."))
                    VStack(spacing: 7 * textScale) {
                        ForEach(Array(processes.enumerated()), id: \.element.id) { rank, process in
                            HStack(spacing: 6) {
                                Text("\(rank + 1)").scaledFont(9).monospacedDigit().adaptiveSecondary().frame(
                                    width: 12 * textScale, alignment: .leading)
                                Text(process.name)
                                    .scaledFont(10).foregroundStyle(.primary).lineLimit(1).truncationMode(.middle)
                                    .help("\(process.name) · PID \(process.id)")
                                Spacer(minLength: 6)
                                Text(value(for: process))
                                    .scaledFont(11, weight: .semibold, design: .rounded).monospacedDigit()
                                    .foregroundStyle(.primary).fixedSize()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    private func value(for process: ProcessUsage) -> String {
        metric == .cpu ? Formatters.formatCPUPercent(process.cpuPercent) : Formatters.formatBytes(process.memoryBytes)
    }
}
