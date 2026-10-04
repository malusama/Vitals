import SwiftUI

struct NetworkDetailView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        NetworkCardView(
            network: appState.metrics.network,
            downloadHistory: appState.networkDownHistory,
            uploadHistory: appState.networkUpHistory
        )
    }
}
