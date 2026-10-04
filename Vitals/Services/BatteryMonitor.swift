import IOKit.ps

final class BatteryMonitor: Sendable {
    var isAvailable: Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        return !sources.isEmpty
    }

    func read() -> BatteryMetrics? {
        BatteryReader.read()
    }
}
