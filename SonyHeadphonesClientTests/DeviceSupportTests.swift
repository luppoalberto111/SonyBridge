import Client
import Either
@testable import SonyHeadphonesClient
import Testing

/// Covers the per-model facts the app shows: which headset it is, how its battery is reported and
/// which equalizer layout it uses.
struct DeviceSupportTests {
    @Test func ultWearResolvesToItsModel() {
        let identifier = Either<DeviceModel, String>(deviceName: "ULT WEAR")

        #expect(identifier == .left(.ultWear))
        #expect(identifier.displayName == "ULT WEAR")
        #expect(HeadphonesUIState(SonyHeadphones(deviceModel: identifier)).deviceHeroModel
            .deviceImage != nil)
    }

    @Test func earbudChargingFlagsReachTheHero() {
        let state = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wf1000Xm5),
            hasDualBattery: true,
            batteryLeft: 80,
            batteryRight: 75,
            batteryLeftCharging: true
        )

        let model = HeadphonesUIState(state).deviceHeroModel

        #expect(model.batteryLeftCharging)
        #expect(!model.batteryRightCharging)
    }

    @Test func tenBandEqualizerReachesTheDomainState() {
        let state = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm6),
            eqBands: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            tenBandEqualizer: true
        )

        let uiState = HeadphonesUIState(state)

        #expect(uiState.tenBandEqualizer)
        #expect(uiState.eqBands.count == 10)
    }

    @Test func capabilitiesAreMirroredIntoTheDomainState() {
        let state = SonyHeadphones(
            connected: true,
            supportsEqualizer: true,
            supportsDsee: true
        )

        let uiState = HeadphonesUIState(state)

        #expect(uiState.supportsEqualizer)
        #expect(uiState.supportsDsee)
    }
}
