import Client

extension HeadphonesState {
    var aboutModel: AboutView.Model {
        .init(
            deviceName: deviceModel?.displayName ?? "",
            connected: connected,
            hasDualBattery: hasDualBattery,
            batteryLeft: batteryLeft,
            batteryRight: batteryRight,
            batteryCase: batteryCase,
            batteryLevel: batteryLevel,
            batteryCharging: batteryCharging,
            codec: codec,
            firmware: firmware,
            protocolVersion: protocolVersion,
            deviceMac: deviceMac
        )
    }

    var deviceHeroModel: DeviceHeroView.Model {
        .init(
            deviceName: deviceModel?.displayName ?? "",
            deviceImage: deviceModel?.left?.image,
            hasDualBattery: hasDualBattery,
            batteryLeft: batteryLeft,
            batteryRight: batteryRight,
            batteryLevel: batteryLevel,
            batteryImage: batteryState.image,
            codec: codec,
            about: aboutModel
        )
    }
}
