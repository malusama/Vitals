import SwiftUI

struct DiskDetailView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        DiskCardView(
            disk: appState.metrics.disk,
            temperature: appState.metrics.thermal.ssdTemperature
        )
    }
}
