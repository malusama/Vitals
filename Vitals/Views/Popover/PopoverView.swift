import SwiftUI

struct PopoverView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    // Keep disclosure and picker state above the optional scroll container so
    // expanded cards stay open when their combined height exceeds the screen.
    @State private var expandedSections: Set<PopoverSection> = []
    @State private var processMetric: ProcessMetric = .cpu

    let maximumSize: CGSize
    var scrollViewport: CGSize? = nil
    var onContentSizeChange: (CGSize) -> Void = { _ in }

    /// Computed in body scope so @Observable tracks all section visibility properties
    private var visibleSections: [PopoverSection] {
        appState.sectionOrder.filter { appState.isSectionVisible($0) }
    }

    var body: some View {
        Group {
            if let scrollViewport {
                ScrollView(.vertical, showsIndicators: false) {
                    dashboard
                }
                .frame(width: scrollViewport.width, height: scrollViewport.height)
            } else {
                dashboard
            }
        }
        .environment(\.glassOpacity, appState.glassOpacity)
        .environment(\.glassVariantEnv, appState.glassVariant)
        .environment(\.textScale, appState.textScale)
        .environment(\.textColorBrightness, appState.textColorBrightness)
        .environment(\.textColorIsDark, colorScheme == .light)
        .foregroundStyle(
            {
                let b =
                    colorScheme == .dark ? appState.textColorBrightness : 1 - appState.textColorBrightness
                return Color(white: b)
            }())
    }

    private var dashboard: some View {
        VStack(spacing: 6) {
            GlassMorphicCard {
                HStack {
                    Text("Vitals")
                        .scaledFont(16, weight: .bold, design: .rounded)
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(
                            URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                    } label: {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .scaledFont(13, weight: .medium)
                            .frame(width: 28 * appState.textScale, height: 28 * appState.textScale)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Activity Monitor")
                    .help("Open Activity Monitor")

                    SettingsLink {
                        Image(systemName: "gearshape.fill")
                            .scaledFont(13, weight: .medium)
                            .frame(width: 28 * appState.textScale, height: 28 * appState.textScale)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Settings")
                    .help("Open Settings")
                }
            }
            ForEach(visibleSections) { section in
                CompactSectionCard(
                    section: section,
                    isExpanded: Binding(
                        get: { expandedSections.contains(section) },
                        set: { expanded in
                            if expanded { expandedSections.insert(section) } else { expandedSections.remove(section) }
                        }
                    ),
                    processMetric: $processMetric
                )
            }
        }
        .padding(10)
        .frame(width: min(280, maximumSize.width))
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { geometry in
            geometry.size
        } action: { size in
            onContentSizeChange(size)
        }
    }
}
