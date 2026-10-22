import AppKit
import Bridge
import Foundation
import SwiftUI

// MARK: - HeadphonesState

/// Everything SwiftUI renders. A value type so it can hop between the actor
/// and the MainActor store without data races.
public struct HeadphonesState: Sendable, Equatable {
    public init() {}
    public var connected = false
    public var connecting = false
    public var deviceName = ""
    public var supportsVpt = false
    public var maxAmbientLevel = 20

    public var mode: SHCAmbientMode = .off
    public var ambientLevel = 10
    public var focusOnVoice = false
    public var focusOnVoiceAvailable = false

    public var batteryLevel = -1
    public var batteryCharging = false
    public var hasDualBattery = false
    public var batteryLeft = -1
    public var batteryRight = -1
    public var batteryCase = -1
    public var eqPreset = 0
    public var supportsEqualizer = false
    public var eqBands = [0, 0, 0, 0, 0]
    public var clearBass = 0
    public var dsee = false

    public var hasAutoPowerOff = false
    public var autoPowerOff = 0
    public var firmware = ""
    public var codec = ""
    public var hasSpeakToChat = false
    public var speakToChat = false
    public var hasAdaptiveVolume = false
    public var adaptiveVolume = false
    public var deviceMac = ""
    public var protocolVersion = ""

    public var errorMessage: String?
}

extension HeadphonesState {
    /// Folds a battery inquiry into state, never clobbering a known reading
    /// with unknown (-1). Battery reads can transiently report unknown while
    /// connected (slow/flaky inquiry, overlapping refresh) — otherwise the
    /// hero flickers to "Connected".
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

    public var deviceImage: Image? {
        let name = deviceName.lowercased().replacingOccurrences(of: " ", with: "-")
        guard NSImage(named: name) != nil else { return nil }
        return Image(name)
    }

    public var batteryState: BatteryState {
        .init(rawValue: batteryLevel, isCharging: batteryCharging)
    }
}

// MARK: - BatteryState

public enum BatteryState: Hashable {
    case empty
    case half
    case full
    case charging

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
