import SwiftUI

/// Process scanning stays in the visibility-gated wrapper; the card only renders.
struct TopProcessesDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var metric: ProcessMetric = .cpu

    var body: some View {
        TopProcessesCardView(byCPU: appState.topProcessesByCPU, byMemory: appState.topProcessesByMemory, metric: $metric)
            .task {
                while !Task.isCancelled {
                    if appState.isPopoverVisible {
                        await appState.refreshTopProcesses()
                    }
                    try? await Task.sleep(for: .seconds(3))
                }
            }
    }
}
