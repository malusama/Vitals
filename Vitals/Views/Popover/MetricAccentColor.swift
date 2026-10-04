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

    static func teal(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.05, green: 0.39, blue: 0.42) : Color(red: 0.31, green: 0.78, blue: 0.79)
    }

    static func green(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.12, green: 0.45, blue: 0.27) : Color(red: 0.4, green: 0.8, blue: 0.48)
    }

    static func orange(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.66, green: 0.32, blue: 0.05) : Color(red: 1.0, green: 0.65, blue: 0.28)
    }

    static func red(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.73, green: 0.19, blue: 0.2) : Color(red: 1.0, green: 0.44, blue: 0.43)
    }
}
