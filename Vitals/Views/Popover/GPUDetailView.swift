import SwiftUI

struct GPUDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GPUCardView(gpu: appState.metrics.gpu)
    }
}
