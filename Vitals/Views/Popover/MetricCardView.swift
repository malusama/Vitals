import SwiftUI

struct MetricCardView<Content: View>: View {

    @Environment(\.textScale) private var textScale

    let metricType: MetricType
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let color: Color
    let history: MetricHistory
    let showsHistory: Bool
    @ViewBuilder let detail: () -> Content

    init(
        metricType: MetricType,
        icon: String,
        title: LocalizedStringKey,
        value: String,
        color: Color = .accentColor,
        history: MetricHistory,
        showsHistory: Bool = true,
        @ViewBuilder detail: @escaping () -> Content = { EmptyView() }
    ) {
        self.metricType = metricType
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.history = history
        self.showsHistory = showsHistory
        self.detail = detail
    }

    var body: some View {
        GlassMorphicCard {
            VStack(alignment: .leading, spacing: 8 * textScale) {
                // Title row
                MetricSectionHeader(title: title, icon: icon, color: color, value: value)

                // Sparkline
                if showsHistory {
                    SparklineView(history: history, color: color, lineWidth: 1.4, lineOpacity: 1)
                        .frame(height: 24)
                        .accessibilityHidden(true)
                }

                // Optional detail content
                detail()
            }
        }
    }
}
