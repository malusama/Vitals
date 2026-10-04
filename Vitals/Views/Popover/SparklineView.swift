import SwiftUI
import Charts

struct SparklineView: View {
    @Environment(\.colorScheme) private var colorScheme
    let history: MetricHistory
    var color: Color = .accentColor
    var upperBound: Double = 1
    var lineWidth: CGFloat = 1.2
    var lineOpacity: Double?

    var body: some View {
        let isLight = colorScheme == .light
        Chart(history.values) { snapshot in
            AreaMark(
                x: .value("Time", snapshot.timestamp),
                y: .value("Value", snapshot.value)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [color.opacity(isLight ? 0.25 : 0.35), color.opacity(isLight ? 0.06 : 0.08), color.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Time", snapshot.timestamp),
                y: .value("Value", snapshot.value)
            )
            .foregroundStyle(color.opacity(lineOpacity ?? (isLight ? 0.7 : 0.9)))
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...upperBound)
        .chartPlotStyle { plotArea in
            plotArea
                .background(color.opacity(isLight ? 0.06 : 0.04))
                .cornerRadius(6)
        }
    }
}
