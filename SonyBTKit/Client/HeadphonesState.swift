import AppKit
import Bridge
import Foundation
import SwiftUI

// MARK: - HeadphonesState

/// Everything SwiftUI renders. A value type so it can hop between the actor
/// and the MainActor store without data races.
public struct HeadphonesState: Sendable, Equatable {
    /// Creates an empty, disconnected snapshot (all defaults).
    public init() {}

    /// True once a connection to a headset is established.
    public var connected = false

    /// True while a connection attempt is in flight (drives the "Connecting…" UI).
    public var connecting = false

    /// The headset's display name, empty when not connected.
    public var deviceName = ""

    /// Whether the v1-only surround/virtual-position commands are usable (v1 devices only).
    public var supportsVpt = false

    /// The maximum ambient level the slider should offer: 19 on v1, 20 on v2 devices.
    public var maxAmbientLevel = 20

    /// The current noise-control mode (off / noise cancelling / ambient sound).
    public var mode: SHCAmbientMode = .off

    /// The ambient-sound level, 1...`maxAmbientLevel`; 0 means ambient sound is off.
    public var ambientLevel = 10

    /// Whether focus on voice (ambient sound emphasises voices) is on.
    public var focusOnVoice = false

    /// Whether focus on voice is offered at the current level (ambient on, level above 2).
    public var focusOnVoiceAvailable = false

    /// Overall battery percentage, or -1 while still unknown.
    public var batteryLevel = -1

    /// Whether the device reported itself as charging.
    public var batteryCharging = false

    /// True for TWS earbuds, which also report per-earbud and case levels.
    public var hasDualBattery = false

    /// Left earbud percentage, or -1 if not applicable/unknown.
    public var batteryLeft = -1

    /// Right earbud percentage, or -1 if not applicable/unknown.
    public var batteryRight = -1

    /// Charging-case percentage, or -1 if not applicable/unknown.
    public var batteryCase = -1

    /// The raw equalizer preset byte (`EQ_PRESET`, e.g. 0x00 Off, 0xA0 Manual).
    public var eqPreset = 0

    /// Whether the device exposes the equalizer (v2 protocol only).
    public var supportsEqualizer = false

    /// The 5 equalizer band gains in -10...10, ordered low to high frequency.
    public var eqBands = [0, 0, 0, 0, 0]

    /// Clear-bass boost in -10...10.
    public var clearBass = 0

    /// Whether DSEE (audio upsampling) is enabled.
    public var dsee = false

    /// Whether the auto-power-off probe succeeded; if false, the setting must not be shown.
    public var hasAutoPowerOff = false

    /// Auto-power-off delay: 0=Off, 1=5 min, 2=30 min, 3=1 hour, 4=3 hours, 5=when taken off.
    public var autoPowerOff = 0

    /// The firmware version string, empty when unknown.
    public var firmware = ""

    /// The active Bluetooth codec ("SBC", "AAC", "LDAC", "aptX", "aptX HD"), empty when unknown.
    public var codec = ""

    /// Whether the speak-to-chat probe succeeded; if false, the toggle must not be shown.
    public var hasSpeakToChat = false

    /// Whether speak-to-chat is enabled on the device.
    public var speakToChat = false

    /// Whether the adaptive-volume probe succeeded; if false, the toggle must not be shown.
    public var hasAdaptiveVolume = false

    /// Whether adaptive volume is enabled on the device.
    public var adaptiveVolume = false

    /// The headset's MAC address, empty when not connected.
    public var deviceMac = ""

    /// Which Sony protocol generation the headset speaks: "v1", "v2", or empty when not connected.
    public var protocolVersion = ""

    /// The last user-facing error message, or nil when the most recent operation succeeded.
    /// Rendered under the controls by `ConnectedView`.
    public var errorMessage: String?
}

extension HeadphonesState {
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
    mutating func mergeBattery(from bridge: HeadphonesBridge) {
        let level = bridge.batteryLevel
        guard level >= 0 else { return }
        batteryLevel = level
        batteryCharging = bridge.batteryCharging
        hasDualBattery = bridge.hasDualBattery
        batteryLeft = bridge.batteryLeft
        batteryRight = bridge.batteryRight
        batteryCase = bridge.batteryCase
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
        var updated = self
        updated.mergeBattery(from: bridge)
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
        updated.deviceName = bridge.deviceName ?? ""
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

    /// Hero image matching the connected model, looked up in the asset catalog.
    ///
    /// The device name is lowercased and space-dashed ("WH-1000XM5" -> "wh-1000xm5") to match the
    /// `NSImage` names in the bundle.
    public var deviceImage: Image? {
        let name = deviceName.lowercased().replacingOccurrences(of: " ", with: "-")
        guard NSImage(named: name) != nil else { return nil }
        return Image(name)
    }

    /// The battery level/charging combination reduced to the icon the UI shows.
    public var batteryState: BatteryState {
        .init(rawValue: batteryLevel, isCharging: batteryCharging)
    }
}

// MARK: - BatteryState

/// The battery buckets the UI renders, derived from a percentage and a charging flag.
public enum BatteryState: Hashable {
    /// 15 % or less.
    case empty
    /// 16–50 %.
    case half
    /// More than 50 %.
    case full
    /// Plugged in / charging, whatever the percentage is.
    case charging

    /// Buckets a raw battery percentage into one of the displayable states.
    ///
    /// - Parameters:
    ///   - rawValue: The percentage, 0...100; negative (unknown) buckets as `.full` since it never
    ///               reaches a level read.
    ///   - isCharging: When true the state is `.charging` regardless of `rawValue`.
    init(rawValue: Int, isCharging: Bool) {
        if isCharging {
            self = .charging
            return
        }
        self = switch rawValue {
            case ...15:
                .empty
            case ...50:
                .half
            default:
                .full
        }
    }

    /// The SF Symbol name for this state, so the view can build an `Image` directly.
    public var image: Image {
        let systemName = switch self {
            case .empty:
                "battery.0"
            case .half:
                "battery.25"
            case .full:
                "battery.100"
            case .charging:
                "bolt.fill"
        }
        return Image(systemName: systemName)
    }
}
