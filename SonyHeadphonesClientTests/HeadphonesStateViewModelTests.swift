import Client
import Testing

@testable import SonyHeadphonesClient

struct HeadphonesStateViewModelTests {
    @Test func deviceHeroModelCarriesIdentityBatteryAndCodec() {
        var state = HeadphonesState()
        state.connected = true
        state.deviceName = "WH-1000XM5"
        state.batteryLevel = 80
        state.codec = "LDAC"
        state.firmware = "2.0.0"
        state.protocolVersion = "v2"
        state.deviceMac = "AA:BB:CC:DD:EE:FF"

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
        var state = HeadphonesState()
        state.hasDualBattery = true
        state.batteryLeft = 80
        state.batteryRight = 75
        state.batteryCase = 50
        state.batteryLevel = -1

        let model = state.deviceHeroModel

        #expect(model.hasDualBattery)
        #expect(model.batteryLeft == 80)
        #expect(model.batteryRight == 75)
        #expect(model.about.batteryCase == 50)
    }

    @Test func dseeModelMirrorsDseeFlag() {
        var state = HeadphonesState()
        state.dsee = true

        #expect(state.dseeModel.dsee)
    }

    @Test func batteryStateMapsLevelsToIcons() {
        #expect(batteryState(level: 10, charging: false) == .empty)
        #expect(batteryState(level: 40, charging: false) == .half)
        #expect(batteryState(level: 90, charging: false) == .full)
        #expect(batteryState(level: 90, charging: true) == .charging)
    }

    private func batteryState(level: Int, charging: Bool) -> BatteryState {
        var state = HeadphonesState()
        state.batteryLevel = level
        state.batteryCharging = charging
        return state.batteryState
    }
}
