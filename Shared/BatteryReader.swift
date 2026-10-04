import Foundation
import IOKit
import IOKit.ps

/// Shared by the live monitor and widget so power direction has one meaning.
enum BatteryReader {
    static func read() -> BatteryMetrics? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        guard let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any]
        else { return nil }

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        var properties: [String: Any] = [:]
        if service != IO_OBJECT_NULL {
            defer { IOObjectRelease(service) }
            var result: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &result, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let result {
                properties = result.takeRetainedValue() as NSDictionary as? [String: Any] ?? [:]
            } else {
                VitalsLog.battery.error("failed to read AppleSmartBattery properties")
            }
        }
        let battery = metrics(powerSource: info, properties: properties)
        if let batteryPower = battery.batteryPowerWatts, let adapterPower = battery.adapterPowerWatts {
            VitalsLog.battery.debug("power: battery=\(batteryPower, privacy: .public)W adapter=\(adapterPower, privacy: .public)W charging=\(battery.isCharging, privacy: .public) pluggedIn=\(battery.isPluggedIn, privacy: .public)")
        }
        return battery
    }

    static func metrics(powerSource info: [String: Any], properties: [String: Any]) -> BatteryMetrics {
        let pluggedIn = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        let reportedCharging = (info[kIOPSIsChargingKey] as? Bool) ?? false
        let data = properties["BatteryData"] as? [String: Any] ?? [:]
        let telemetry = properties["PowerTelemetryData"] as? [String: Any] ?? [:]
        let adapter = properties["AdapterDetails"] as? [String: Any] ?? [:]

        // Telemetry fields are mW. Older Macs can use signed mA × mV instead.
        let batteryPower = signedMilliValue(telemetry["BatteryPower"]).map { $0 / 1_000 }
            ?? signedMilliValue(data["BatteryPower"]).map { $0 / 1_000 }
            ?? power(current: properties["InstantAmperage"] ?? properties["Amperage"], voltage: properties["Voltage"])

        // A charging flag can remain true while a low-power adapter is connected
        // and the battery supplies the shortfall. Measured flow takes precedence.
        let charging = batteryPower.map { $0 > 0.1 } ?? reportedCharging
        let discharging = batteryPower.map { $0 < -0.1 } ?? (!pluggedIn && !charging)
        let adapterPower: Double? = pluggedIn
            ? (positiveValue(telemetry["SystemPowerIn"]).map { $0 / 1_000 }
               ?? power(current: telemetry["SystemCurrentIn"], voltage: telemetry["SystemVoltageIn"]))
            : 0
        let adapterLimit = pluggedIn ? positiveValue(adapter["Watts"]) : nil

        let minutes: Int? = if charging {
            validMinutes(info[kIOPSTimeToFullChargeKey]) ?? validMinutes(properties["AvgTimeToFull"])
                ?? validMinutes(data["AvgTimeToFull"])
        } else if discharging {
            validMinutes(info[kIOPSTimeToEmptyKey]) ?? validMinutes(properties["AvgTimeToEmpty"])
                ?? validMinutes(data["AvgTimeToEmpty"])
        } else {
            nil
        }

        return BatteryMetrics(
            percentage: info[kIOPSCurrentCapacityKey] as? Int ?? 0,
            isCharging: charging,
            isPluggedIn: pluggedIn,
            timeRemaining: minutes.map { TimeInterval($0) * 60 },
            cycleCount: properties["CycleCount"] as? Int,
            maxCapacity: properties["AppleRawMaxCapacity"] as? Int
                ?? properties["NominalChargeCapacity"] as? Int
                ?? data["NominalChargeCapacity"] as? Int,
            designCapacity: properties["DesignCapacity"] as? Int ?? data["DesignCapacity"] as? Int,
            batteryPowerWatts: batteryPower,
            adapterPowerWatts: adapterPower,
            adapterMaxPowerWatts: adapterLimit
        )
    }

    private static func signedMilliValue(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        // IORegistry also exposes negative signed readings as unsigned 32/64-bit
        // two's-complement numbers on some Macs. Decode the underlying low bits.
        return Double(number.int32Value)
    }

    private static func positiveValue(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let value = number.doubleValue
        return value.isFinite && value >= 0 ? value : nil
    }

    private static func power(current: Any?, voltage: Any?) -> Double? {
        guard let current = signedMilliValue(current), let voltage = positiveValue(voltage), voltage > 0 else { return nil }
        return current * voltage / 1_000_000
    }

    private static func validMinutes(_ value: Any?) -> Int? {
        guard let minutes = value as? Int, minutes > 0, minutes < 65_535 else { return nil }
        return minutes
    }
}
