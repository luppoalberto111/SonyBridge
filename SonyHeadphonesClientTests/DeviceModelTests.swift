import Client
import Either
import Testing

struct DeviceModelTests {
    @Test(arguments: DeviceModel.allCases)
    func stockNameResolvesToModel(_ model: DeviceModel) {
        let identifier = Either<DeviceModel, String>(deviceName: model.rawValue)

        #expect(DeviceModel(rawValue: model.rawValue) == model)
        #expect(identifier == .left(model))
        #expect(identifier.displayName == model.rawValue)
        #expect(identifier.image != nil)
    }

    @Test func renamedDeviceKeepsRawName() {
        let identifier = Either<DeviceModel, String>(deviceName: "Marek's WH-1000XM5")

        #expect(identifier == .right("Marek's WH-1000XM5"))
        #expect(identifier.displayName == "Marek's WH-1000XM5")
        #expect(identifier.image == nil)
    }

    @Test func stateResolvesItsDeviceModel() {
        var state = HeadphonesState()
        state.deviceName = "WF-1000XM4"

        #expect(state.deviceModel == .left(.wf1000Xm4))
        #expect(state.deviceImage != nil)
    }
}
