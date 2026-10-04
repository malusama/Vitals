import SwiftUI

/// Accent marks on glass need stronger colors in light appearance.
/// Keep measurements in the primary text color rather than relying on the accent.
enum MetricAccentColor {
    static func blue(for scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color(red: 0.05, green: 0.36, blue: 0.66)
            : Color(red: 0.35, green: 0.67, blue: 1.0)
    }

    static func purple(for scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color(red: 0.45, green: 0.28, blue: 0.68)
            : Color(red: 0.75, green: 0.56, blue: 0.96)
    }
}
