import SwiftUI

struct MemoryDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        MemoryCardView(memory: appState.metrics.memory)
    }
}
