import SwiftUI

struct WiFiDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        WiFiCardView(wifi: appState.metrics.wifi)
    }
}
