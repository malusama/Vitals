import Foundation
import IOKit
import IOKit.ps
import os

/// Stateless metric readers compiled into the widget extension so the Storage
/// and Battery widgets can render real data even when the App Group container
/// is unavailable (unsigned builds) or its `metrics.json` is stale.
///
/// Both reads work inside the widget's sandbox: disk capacity via `statfs`
/// (`URL.resourceValues`, matching Finder's free-space figure) and battery via
/// IOPowerSources plus IORegistry `AppleSmartBattery` for health and cycles.
/// The readers are one-shot — no caching — because the widget process is
/// short-lived and each timeline pass gets a fresh value.
enum LocalMetrics {

    // MARK: - Disk

    /// Reads capacity and free space for the boot volume. Disk I/O throughput
    /// is not measurable from a one-shot widget process (it needs two samples
    /// over time), so read/write speeds are reported as 0.
    static func readDisk() -> DiskMetrics {
        let url = URL(fileURLWithPath: "/")
        var totalSpace: UInt64 = 0
        var freeSpace: UInt64 = 0
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
            ])
            totalSpace = UInt64(values.volumeTotalCapacity ?? 0)
            freeSpace = UInt64(values.volumeAvailableCapacityForImportantUsage ?? 0)
        } catch {
            VitalsLog.widgets.error("LocalMetrics.readDisk failed: \(error.localizedDescription)")
        }
        let usedSpace = totalSpace > freeSpace ? totalSpace - freeSpace : 0
        return DiskMetrics(
            totalSpace: totalSpace,
            usedSpace: usedSpace,
            freeSpace: freeSpace,
            readSpeed: 0,
            writeSpeed: 0
        )
    }

    // MARK: - Battery

    /// Uses the same power-direction and health reader as the live monitor.
    static func readBattery() -> BatteryMetrics? {
        BatteryReader.read()
    }

    // MARK: - System info

    /// Reads the exact boot instant via `sysctl(KERN_BOOTTIME)`. Handing this
    /// fixed `Date` to `Text(_:style:.relative)` lets SwiftUI tick the uptime
    /// live inside the widget process with no timeline refreshes. Falls back to
    /// deriving the boot date from `ProcessInfo.systemUptime` if sysctl fails.
    static func readBootDate() -> Date {
        var boot = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        if sysctl(&mib, 2, &boot, &size, nil, 0) == 0, boot.tv_sec != 0 {
            return Date(timeIntervalSince1970: TimeInterval(boot.tv_sec) + TimeInterval(boot.tv_usec) / 1_000_000)
        }
        VitalsLog.systemInfo.error("LocalMetrics.readBootDate: sysctl KERN_BOOTTIME failed (errno=\(errno, privacy: .public))")
        return Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
    }

    /// Human-readable macOS version string, e.g. "macOS 26.0.1".
    static func readOSVersion() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    /// Hardware model identifier via `sysctl hw.model` (e.g. "Mac15,3"), matching
    /// the main app's `SystemInfoMonitor`. Returns "Mac" if the read fails.
    static func readModelName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else {
            VitalsLog.systemInfo.warning("LocalMetrics.readModelName: sysctl hw.model returned no data")
            return "Mac"
        }
        var model = [UInt8](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(decoding: model.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
}
