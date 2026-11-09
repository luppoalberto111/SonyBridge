import Client
@testable import SonyHeadphonesClient
import Testing

struct HeadphonesStateViewModelTests {
    @Test func deviceHeroModelCarriesIdentityBatteryAndCodec() {
        let state = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            batteryLevel: 80,
            firmware: "2.0.0",
            codec: "LDAC",
            deviceMac: "AA:BB:CC:DD:EE:FF",
            protocolVersion: "v2"
        )
        let model = state.deviceHeroModel

        #expect(model.deviceName == "WH-1000XM5")
        #expect(model.batteryLevel == 80)
        #expect(model.hasDualBattery == false)
        #expect(model.codec == "LDAC")
        #expect(model.about.deviceName == "WH-1000XM5")
        #expect(model.about.connected)
        #expect(model.about.firmware == "2.0.0")
        #expect(model.about.protocolVersion == "v2")
        #expect(model.about.deviceMac == "AA:BB:CC:DD:EE:FF")
    }

    @Test func deviceHeroModelCarriesDualBatteryReadings() {
        let state = SonyHeadphones(
            batteryLevel: -1,
            hasDualBattery: true,
            batteryLeft: 80,
            batteryRight: 75,
            batteryCase: 50
        )

        let model = state.deviceHeroModel

        #expect(model.hasDualBattery)
        #expect(model.batteryLeft == 80)
        #expect(model.batteryRight == 75)
        #expect(model.about.batteryCase == 50)
    }

    @Test func batteryStateMapsLevelsToIcons() {
        #expect(batteryState(level: 10, charging: false) == .empty)
        #expect(batteryState(level: 40, charging: false) == .half)
        #expect(batteryState(level: 90, charging: false) == .full)
        #expect(batteryState(level: 90, charging: true) == .charging)
    }

    private func batteryState(level: Int, charging: Bool) -> BatteryState {
        let state = SonyHeadphones(batteryLevel: level, batteryCharging: charging)
        return state.batteryState
    }
}
