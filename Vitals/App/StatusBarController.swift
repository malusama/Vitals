import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var hostingView: NSHostingView<AnyView>!
    private var appState: AppState
    private var globalMonitor: Any?
    private var availableFrame = CGRect(x: 0, y: 0, width: 1_200, height: 800)
    private var contentSize = CGSize.zero
    private var anchorX: CGFloat = 0
    private var needsScrolling = false

    init(appState: AppState) {
        self.appState = appState
        setupStatusItem()
        setupPanel()
    }

    nonisolated deinit {
        // The global event monitor needs an explicit NSEvent.removeMonitor —
        // ARC does not clean it up. It is removed in hidePanel(), which runs
        // whenever the panel closes, so nothing is left to release here.
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePanel(_:))
            button.target = self
            updateLabel()
        }

        // Redraw the label whenever new metrics arrive, driven by SystemMonitor's
        // polling — no separate timer, so the label stays in sync with the data.
        appState.onMetricsUpdate = { [weak self] in
            self?.updateLabel()
        }
    }

    private func updateLabel() {
        guard let button = statusItem.button else { return }
        let m = appState.metrics
        let th = m.thermal

        let attachment = NSMutableAttributedString()
        let fontSize: CGFloat = 12
        let iconSize: CGFloat = 12
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .baselineOffset: 0]

        func addIcon(_ name: String) {
            if let img = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
                let configured = img.withSymbolConfiguration(config) ?? img
                let a = NSTextAttachment()
                a.image = configured
                attachment.append(NSAttributedString(attachment: a))
                attachment.append(NSAttributedString(string: " ", attributes: attrs))
            }
        }

        func addText(_ text: String) {
            attachment.append(NSAttributedString(string: text, attributes: attrs))
        }

        func addSpacer() {
            attachment.append(NSAttributedString(string: "  ", attributes: attrs))
        }

        for item in appState.menuBarOrder {
            guard appState.isMenuBarItemEnabled(item) else { continue }
            switch item {
            case .cpuUsage:
                addIcon("cpu.fill")
                addText("\(Int(m.cpu.totalUsage * 100))%")
            case .cpuTemp:
                guard let temp = th.cpuTemperature else { continue }
                addIcon("thermometer.medium")
                addText("\(Int(temp))°")
            case .fanRPM:
                guard let rpm = th.fanRPM else { continue }
                addIcon("fan.fill")
                addText(rpm > 0 ? "\(rpm)" : String(localized: "Off"))
            case .gpu:
                guard let util = m.gpu.utilization else { continue }
                addIcon("display")
                addText("\(Int(util * 100))%")
            case .power:
                guard let watts = th.systemPower else { continue }
                addIcon("bolt.fill")
                addText(String(format: "%.0fW", watts))
            case .memory:
                addIcon("memorychip.fill")
                addText(Formatters.formatBytes(m.memory.used))
            case .networkDown:
                addIcon("arrow.down")
                addText(Formatters.formatBytesPerSec(m.network.downloadSpeed))
            case .networkUp:
                addIcon("arrow.up")
                addText(Formatters.formatBytesPerSec(m.network.uploadSpeed))
            case .battery:
                guard let bat = m.battery else { continue }
                addIcon(bat.isCharging ? "battery.100percent.bolt" : "battery.75percent")
                addText("\(bat.percentage)%")
            case .batteryTime:
                guard let bat = m.battery else { continue }
                addIcon("clock")
                if let time = bat.timeRemaining, time > 0 {
                    addText(Formatters.formatDuration(time))
                } else {
                    addText("—")
                }
            case .disk:
                addIcon("internaldrive.fill")
                addText("\(Int(m.disk.usageRatio * 100))%")
            case .ip:
                guard let ip = m.wifi.localIP else { continue }
                addIcon("network")
                addText(ip)
            }
            addSpacer()
        }

        button.attributedTitle = attachment
    }

    // MARK: - Transparent Glass Panel

    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 290, height: 500),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow

        hostingView = NSHostingView(rootView: AnyView(EmptyView()))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        panel.contentView = hostingView
        updatePopoverRoot()
    }

    @objc private func togglePanel(_ sender: Any?) {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button else { return }
        appState.refreshBattery()
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero

        guard
            let screen = button.window?.screen
                ?? NSScreen.screens.first(where: { $0.frame.intersects(buttonFrame) })
                ?? NSScreen.main ?? NSScreen.screens.first
        else { return }
        let visibleFrame = screen.visibleFrame
        let top = min(buttonFrame.minY - 8, visibleFrame.maxY)
        availableFrame = CGRect(
            x: visibleFrame.minX + 8, y: visibleFrame.minY + 8,
            width: max(1, visibleFrame.width - 16), height: max(1, top - visibleFrame.minY - 8)
        )
        anchorX = buttonFrame.midX
        needsScrolling = false
        updatePopoverRoot()
        hostingView.needsLayout = true
        hostingView.layoutSubtreeIfNeeded()
        contentSize = hostingView.fittingSize
        needsScrolling = contentSize.height > availableFrame.height
        if needsScrolling { updatePopoverRoot() }
        resizePanel()
        panel.orderFrontRegardless()
        appState.isPopoverVisible = true
        VitalsLog.app.debug(
            "popover: content=\(self.contentSize.width, privacy: .public)x\(self.contentSize.height, privacy: .public) available=\(self.availableFrame.width, privacy: .public)x\(self.availableFrame.height, privacy: .public) scrolling=\(self.needsScrolling, privacy: .public)"
        )

        // Close on outside click
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            self?.hidePanel()
        }
    }

    private func updatePopoverRoot() {
        let viewport =
            needsScrolling ? CGSize(width: contentSize.width, height: availableFrame.height) : nil
        hostingView.rootView = AnyView(
            PopoverView(maximumSize: availableFrame.size, scrollViewport: viewport) { [weak self] size in
                self?.contentSizeDidChange(size)
            }
            .environment(appState)
        )
    }

    private func contentSizeDidChange(_ size: CGSize) {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
        let previousWidth = contentSize.width
        contentSize = size
        guard panel.isVisible else { return }
        let shouldScroll = size.height > availableFrame.height
        if shouldScroll != needsScrolling || (shouldScroll && previousWidth != size.width) {
            needsScrolling = shouldScroll
            updatePopoverRoot()
        }
        resizePanel()
    }

    private func resizePanel() {
        let width = min(ceil(contentSize.width), availableFrame.width)
        let height = min(ceil(contentSize.height), availableFrame.height)
        let x = min(max(anchorX - width / 2, availableFrame.minX), availableFrame.maxX - width)
        let frame = CGRect(x: x, y: availableFrame.maxY - height, width: width, height: height)
        if panel.frame != frame { panel.setFrame(frame, display: true) }
    }

    private func hidePanel() {
        panel.orderOut(nil)
        appState.isPopoverVisible = false
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }
}
