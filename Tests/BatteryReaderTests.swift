import Foundation
import IOKit.ps
import Testing

struct BatteryReaderTests {
    private var acSource: [String: Any] {
        [kIOPSCurrentCapacityKey: 82, kIOPSIsChargingKey: true,
         kIOPSPowerSourceStateKey: kIOPSACPowerValue,
         kIOPSTimeToEmptyKey: 0, kIOPSTimeToFullChargeKey: -1]
    }

    @Test func lowPowerAdapterDoesNotMeanBatteryCharging() {
        let battery = BatteryReader.metrics(powerSource: acSource, properties: [
            "PowerTelemetryData": ["BatteryPower": -31_423, "SystemPowerIn": 25_077],
            "AdapterDetails": ["Watts": 27], "AvgTimeToEmpty": 103,
        ])
        #expect(!battery.isCharging)
        #expect(battery.isDischarging)
        #expect(battery.statusLabel == "AC + Battery")
        #expect(battery.chargePowerWatts == 0)
        #expect(battery.dischargePowerWatts == 31.423)
        #expect(battery.adapterPowerWatts == 25.077)
        #expect(battery.adapterMaxPowerWatts == 27)
        #expect(battery.timeRemaining == TimeInterval(103 * 60))
    }

    @Test func chargingUsesTimeToFullEvenIfTimeToEmptyExists() {
        var source = acSource
        source[kIOPSTimeToFullChargeKey] = 60
        source[kIOPSTimeToEmptyKey] = 20
        let battery = BatteryReader.metrics(powerSource: source, properties: [
            "BatteryData": ["BatteryPower": 12_000],
        ])
        #expect(battery.isCharging)
        #expect(!battery.isDischarging)
        #expect(battery.chargePowerWatts == 12)
        #expect(battery.dischargePowerWatts == 0)
        #expect(battery.timeRemaining == 3_600)
    }

    @Test(arguments: [NSNumber(value: -2_890),
                      NSNumber(value: UInt32(bitPattern: -2_890)),
                      NSNumber(value: UInt64(bitPattern: -2_890))])
    func signedAndUnsignedCurrentReadings(current: NSNumber) throws {
        let battery = BatteryReader.metrics(powerSource: acSource, properties: [
            "Amperage": current, "Voltage": 12_191,
        ])
        let power = try #require(battery.batteryPowerWatts)
        #expect(abs(power + 35.23199) < 0.000001)
        #expect(battery.isDischarging)
        #expect(!battery.isCharging)
    }

    @Test func missingReadingsDoNotTurnAdapterLimitIntoMeasuredPower() {
        let battery = BatteryReader.metrics(powerSource: acSource, properties: ["AdapterDetails": ["Watts": 27]])
        #expect(battery.isCharging) // IOPS fallback when no signed measurement exists.
        #expect(battery.batteryPowerWatts == nil)
        #expect(battery.adapterPowerWatts == nil)
        #expect(battery.chargePowerWatts == nil)
        #expect(Formatters.formatWatts(battery.adapterPowerWatts) == "—")
    }

    @Test func unpluggedIgnoresStaleAdapterTelemetry() {
        var source = acSource
        source[kIOPSPowerSourceStateKey] = kIOPSBatteryPowerValue
        source[kIOPSIsChargingKey] = false
        let battery = BatteryReader.metrics(powerSource: source, properties: [
            "PowerTelemetryData": ["BatteryPower": -20_000, "SystemPowerIn": 25_000],
            "AdapterDetails": ["Watts": 27],
        ])
        #expect(!battery.isPluggedIn)
        #expect(battery.adapterPowerWatts == 0)
        #expect(battery.adapterMaxPowerWatts == nil)
        #expect(battery.dischargePowerWatts == 20)
    }

    @Test func idleBatteryOverridesChargingFlag() {
        let battery = BatteryReader.metrics(powerSource: acSource, properties: [
            "BatteryData": ["BatteryPower": 0], "AvgTimeToEmpty": 103,
        ])
        #expect(!battery.isCharging)
        #expect(!battery.isDischarging)
        #expect(battery.timeRemaining == nil)
        #expect(battery.chargePowerWatts == 0)
        #expect(battery.dischargePowerWatts == 0)
    }

    @Test(arguments: [-2, -1, 0, 65_535])
    func unavailableTimeIsNotAnInfiniteEstimate(minutes: Int) {
        var source = acSource
        source[kIOPSTimeToEmptyKey] = minutes
        let battery = BatteryReader.metrics(powerSource: source, properties: [
            "BatteryData": ["BatteryPower": -20_000], "AvgTimeToEmpty": minutes,
        ])
        #expect(battery.timeRemaining == nil)
    }

    @Test func oldSharedSnapshotsStillDecode() throws {
        let data = Data(#"{"percentage":82,"isCharging":true,"isPluggedIn":true}"#.utf8)
        let battery = try JSONDecoder().decode(BatteryMetrics.self, from: data)
        #expect(battery.percentage == 82)
        #expect(battery.batteryPowerWatts == nil)
        #expect(battery.adapterPowerWatts == nil)
    }
}
