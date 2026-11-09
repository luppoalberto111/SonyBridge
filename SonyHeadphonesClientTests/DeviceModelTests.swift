import Client
import Either
@testable import SonyHeadphonesClient
import Testing

struct DeviceModelTests {
    @Test(arguments: DeviceModel.allCases)
    func stockNameResolvesToModel(_ model: DeviceModel) {
        let identifier = Either<DeviceModel, String>(deviceName: model.rawValue)

        #expect(DeviceModel(rawValue: model.rawValue) == model)
        #expect(identifier == .left(model))
        #expect(identifier.displayName == model.rawValue)
    }

    @Test func renamedDeviceKeepsRawName() {
        let identifier = Either<DeviceModel, String>(deviceName: "Marek's WH-1000XM5")

        #expect(identifier == .right("Marek's WH-1000XM5"))
        #expect(identifier.displayName == "Marek's WH-1000XM5")

        let state = SonyHeadphones(deviceModel: identifier)
        #expect(state.deviceHeroModel.deviceImage == nil)
    }

    @Test func stateResolvesItsDeviceModel() {
        let state =
            SonyHeadphones(deviceModel: Either<DeviceModel, String>(deviceName: "WF-1000XM4"))
        #expect(state.deviceModel == .left(.wf1000Xm4))
        #expect(state.deviceHeroModel.deviceImage != nil)
    }
}
