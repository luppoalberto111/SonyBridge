import Bridge
import Either
import Foundation

// MARK: - SonyHeadphones

/// Everything SwiftUI renders. A value type so it can hop between the actor
/// and the MainActor store without data races.
public struct SonyHeadphones: Sendable, Equatable {
    /// True once a connection to a headset is established.
    public internal(set) var connected: Bool

    /// The connected model, resolved from the advertised Bluetooth name.
    public internal(set) var deviceModel: Either<DeviceModel, String>?

    /// Whether the v1-only surround/virtual-position commands are usable (v1 devices only).
    public internal(set) var supportsVpt: Bool

    /// The maximum ambient level the slider should offer: 19 on v1, 20 on v2 devices.
    public internal(set) var maxAmbientLevel: Int

    /// The current noise-control mode (off / noise cancelling / ambient sound).
    public var mode: SHCAmbientMode

    /// The ambient-sound level, 1...`maxAmbientLevel`; 0 means ambient sound is off.
    public var ambientLevel: Int

    /// Whether focus on voice (ambient sound emphasises voices) is on.
    public internal(set) var focusOnVoice: Bool

    /// Whether focus on voice is offered at the current level (ambient on, level above 2).
    public internal(set) var focusOnVoiceAvailable: Bool

    /// Overall battery percentage, or -1 while still unknown.
    public internal(set) var batteryLevel: Int

    /// Whether the device reported itself as charging.
    public internal(set) var batteryCharging: Bool

    /// True for TWS earbuds, which also report per-earbud and case levels.
    public internal(set) var hasDualBattery: Bool

    /// Left earbud percentage, or -1 if not applicable/unknown.
    public internal(set) var batteryLeft: Int

    /// Right earbud percentage, or -1 if not applicable/unknown.
    public internal(set) var batteryRight: Int

    /// Charging-case percentage, or -1 if not applicable/unknown.
    public internal(set) var batteryCase: Int

    /// The raw equalizer preset byte (`EQ_PRESET`, e.g. 0x00 Off, 0xA0 Manual).
    public internal(set) var eqPreset: Int

    /// Whether the device exposes the equalizer (v2 protocol only).
    public internal(set) var supportsEqualizer: Bool

    /// The 5 equalizer band gains in -10...10, ordered low to high frequency.
    public var eqBands: [Int]

    /// Clear-bass boost in -10...10.
    public var clearBass: Int

    /// Whether DSEE (audio upsampling) is enabled.
    public internal(set) var dsee: Bool

    /// Whether the auto-power-off probe succeeded; if false, the setting must not be shown.
    public internal(set) var hasAutoPowerOff: Bool

    /// Auto-power-off delay: 0=Off, 1=5 min, 2=30 min, 3=1 hour, 4=3 hours, 5=when taken off.
    public internal(set) var autoPowerOff: Int

    /// The firmware version string, empty when unknown.
    public internal(set) var firmware: String

    /// The active Bluetooth codec ("SBC", "AAC", "LDAC", "aptX", "aptX HD"), empty when unknown.
    public internal(set) var codec: String

    /// Whether the speak-to-chat probe succeeded; if false, the toggle must not be shown.
    public internal(set) var hasSpeakToChat: Bool

    /// Whether speak-to-chat is enabled on the device.
    public internal(set) var speakToChat: Bool

    /// Whether the adaptive-volume probe succeeded; if false, the toggle must not be shown.
    public internal(set) var hasAdaptiveVolume: Bool

    /// Whether adaptive volume is enabled on the device.
    public internal(set) var adaptiveVolume: Bool

    /// The headset's MAC address, empty when not connected.
    public internal(set) var deviceMac: String

    /// Which Sony protocol generation the headset speaks: "v1", "v2", or empty when not connected.
    public internal(set) var protocolVersion: String

    public init(
        connected: Bool = false,
        deviceModel: Either<DeviceModel, String>? = nil,
        supportsVpt: Bool = false,
        maxAmbientLevel: Int = 20,
        mode: SHCAmbientMode = .off,
        ambientLevel: Int = 10,
        focusOnVoice: Bool = false,
        focusOnVoiceAvailable: Bool = false,
        batteryLevel: Int = -1,
        batteryCharging: Bool = false,
        hasDualBattery: Bool = false,
        batteryLeft: Int = -1,
        batteryRight: Int = -1,
        batteryCase: Int = -1,
        eqPreset: Int = 0,
        supportsEqualizer: Bool = false,
        eqBands: [Int] = [0, 0, 0, 0, 0],
        clearBass: Int = 0,
        dsee: Bool = false,
        hasAutoPowerOff: Bool = false,
        autoPowerOff: Int = 0,
        firmware: String = "",
        codec: String = "",
        hasSpeakToChat: Bool = false,
        speakToChat: Bool = false,
        hasAdaptiveVolume: Bool = false,
        adaptiveVolume: Bool = false,
        deviceMac: String = "",
        protocolVersion: String = ""
    ) {
        self.connected = connected
        self.deviceModel = deviceModel
        self.supportsVpt = supportsVpt
        self.maxAmbientLevel = maxAmbientLevel
        self.mode = mode
        self.ambientLevel = ambientLevel
        self.focusOnVoice = focusOnVoice
        self.focusOnVoiceAvailable = focusOnVoiceAvailable
        self.batteryLevel = batteryLevel
        self.batteryCharging = batteryCharging
        self.hasDualBattery = hasDualBattery
        self.batteryLeft = batteryLeft
        self.batteryRight = batteryRight
        self.batteryCase = batteryCase
        self.eqPreset = eqPreset
        self.supportsEqualizer = supportsEqualizer
        self.eqBands = eqBands
        self.clearBass = clearBass
        self.dsee = dsee
        self.hasAutoPowerOff = hasAutoPowerOff
        self.autoPowerOff = autoPowerOff
        self.firmware = firmware
        self.codec = codec
        self.hasSpeakToChat = hasSpeakToChat
        self.speakToChat = speakToChat
        self.hasAdaptiveVolume = hasAdaptiveVolume
        self.adaptiveVolume = adaptiveVolume
        self.deviceMac = deviceMac
        self.protocolVersion = protocolVersion
    }
}

extension SonyHeadphones {
    // Folds a battery inquiry into state, never clobbering a known reading
    // with unknown (-1). Battery reads can transiently report unknown while
    // connected (slow/flaky inquiry, overlapping refresh) — otherwise the
    // hero flickers to "Connected".
    /// Applies the bridge's battery readings, but only while they contain a real level.
    ///
    /// A transiently unknown reading (`batteryLevel < 0`) is ignored wholesale, so an in-flight or
    /// failed inquiry can't blank out a percentage the user is already looking at.
    ///
    /// - Parameter bridge: The bridge to read the battery properties from.
    func updatedBattery(from bridge: HeadphonesBridge) -> Self {
        let level = bridge.batteryLevel
        guard level >= 0 else { return self }
        var updated = self
        updated.batteryLevel = level
        updated.batteryCharging = bridge.batteryCharging
        updated.hasDualBattery = bridge.hasDualBattery
        updated.batteryLeft = bridge.batteryLeft
        updated.batteryRight = bridge.batteryRight
        updated.batteryCase = bridge.batteryCase

        return updated
    }

    /// Refreshes everything the slow reads can change: battery, equalizer, DSEE and the optional features.
    ///
    /// Connection/ambient values are deliberately left alone — those come from
    /// ``synced(with:)``. Firmware and codec only overwrite an empty local value, so a missing probe
    /// can't erase a previously known version.
    ///
    /// - Parameter bridge: The bridge whose properties to mirror.
    /// - Returns: A new snapshot with the refreshed values.
    func updated(with bridge: HeadphonesBridge) -> Self {
        var updated = updatedBattery(from: bridge)
        updated.eqPreset = bridge.eqPreset
        updated.clearBass = bridge.clearBass
        updated.dsee = bridge.dsee
        updated.eqBands = (0 ..< 5).map { bridge.equalizerBand(at: $0) }
        updated.hasAutoPowerOff = bridge.hasAutoPowerOff
        updated.autoPowerOff = bridge.autoPowerOff
        let firmware = bridge.firmware ?? ""
        if !firmware.isEmpty { updated.firmware = firmware }
        let codec = bridge.codec ?? ""
        if !codec.isEmpty { updated.codec = codec }
        updated.hasSpeakToChat = bridge.hasSpeakToChat
        updated.speakToChat = bridge.speakToChat
        updated.hasAdaptiveVolume = bridge.hasAdaptiveVolume
        updated.adaptiveVolume = bridge.adaptiveVolume
        return updated
    }

    /// Mirrors the connection identity and ambient state after a connect or an applied mode change.
    ///
    /// An ambient level of 0 is ignored, matching ``mergeBattery(from:)``: a level that hasn't been
    /// read back yet must not reset the slider the user just set.
    ///
    /// - Parameter bridge: The bridge whose properties to mirror.
    /// - Returns: A new snapshot with `connected`, device identity, capabilities and ambient state set.
    func synced(with bridge: HeadphonesBridge) -> Self {
        var updated = self
        updated.connected = bridge.connected
        updated.deviceModel = bridge.deviceName.map { .init(deviceName: $0) }
        updated.deviceMac = bridge.deviceMac ?? ""
        updated.protocolVersion = bridge.protocolVersionString ?? ""
        updated.supportsVpt = bridge.supportsVpt
        updated.supportsEqualizer = bridge.supportsEqualizer
        updated.maxAmbientLevel = bridge.maxAmbientLevel
        updated.mode = bridge.mode
        let level = bridge.ambientLevel
        if level > 0 { updated.ambientLevel = level }
        updated.focusOnVoice = bridge.focusOnVoice
        updated.focusOnVoiceAvailable = bridge.focusOnVoiceAvailable
        return updated
    }

    /// The battery level/charging combination reduced to the icon the UI shows.
    public var batteryState: BatteryState {
        .init(rawValue: batteryLevel, isCharging: batteryCharging)
    }
}
