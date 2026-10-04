import SwiftUI

struct SystemInfoDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        SystemInfoCardView(info: appState.metrics.systemInfo)
    }
}
