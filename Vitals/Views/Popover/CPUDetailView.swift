import SwiftUI

struct CPUDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        CPUCardView(cpu: appState.metrics.cpu, thermal: appState.metrics.thermal, history: appState.cpuHistory)
    }
}
