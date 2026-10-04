import SwiftUI

struct BatteryDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let battery = appState.metrics.battery {
            BatteryCardView(
                battery: battery,
                temperature: appState.metrics.thermal.batteryTemperature,
                history: appState.batteryHistory
            )
        }
    }
}
