import Client

extension HeadphonesState {
    var aboutModel: AboutView.Model {
        .init(
            deviceName: deviceName,
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

    var ambientModel: AmbientView.Model {
        .init(
            mode: mode,
            ambientLevel: ambientLevel,
            maxAmbientLevel: maxAmbientLevel,
            focusOnVoice: focusOnVoice,
            focusOnVoiceAvailable: focusOnVoiceAvailable
        )
    }

    var settingsModel: SettingsView.Model {
        .init(
            hasAdaptiveVolume: hasAdaptiveVolume,
            adaptiveVolume: adaptiveVolume,
            hasSpeakToChat: hasSpeakToChat,
            speakToChat: speakToChat,
            hasAutoPowerOff: hasAutoPowerOff,
            autoPowerOff: AutoPowerOffOption(rawValue: autoPowerOff) ?? .off
        )
    }

    var equalizerModel: EqualizerView.Model {
        .init(
            eqPreset: eqPreset,
            eqBands: eqBands,
            clearBass: clearBass
        )
    }

    var dseeModel: DseeView.Model {
        .init(dsee: dsee)
    }

    var deviceHeroModel: DeviceHeroView.Model {
        .init(
            deviceName: deviceName,
            deviceImage: deviceImage,
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
