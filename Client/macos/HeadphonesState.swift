//
//  HeadphonesState.swift
//  Immutable snapshot of everything SwiftUI renders.
//

import Foundation

/// Everything SwiftUI renders. A value type so it can hop between the actor
/// and the MainActor store without data races.
struct HeadphonesState: Sendable {
    var connected = false
    var connecting = false
    var deviceName = ""
    var supportsVpt = false
    var maxAmbientLevel = 20

    var mode: SHCAmbientMode = .off
    var ambientLevel = 10
    var focusOnVoice = false
    var focusOnVoiceAvailable = false

    var batteryLevel = -1
    var batteryCharging = false
    var hasDualBattery = false
    var batteryLeft = -1
    var batteryRight = -1
    var batteryCase = -1
    var eqPreset = 0
    var supportsEqualizer = false
    var eqBands = [0, 0, 0, 0, 0]
    var clearBass = 0
    var dsee = false

    var hasAutoPowerOff = false
    var autoPowerOff = 0
    var firmware = ""
    var codec = ""
    var hasSpeakToChat = false
    var speakToChat = false
    var hasAdaptiveVolume = false
    var adaptiveVolume = false
    var deviceMac = ""
    var protocolVersion = ""

    var errorMessage: String?
}

extension HeadphonesState {
    func updated(with bridge: HeadphonesBridge) -> Self {
        var updated = self
        updated.batteryLevel = bridge.batteryLevel
        updated.batteryCharging = bridge.batteryCharging
        updated.hasDualBattery = bridge.hasDualBattery
        updated.batteryLeft = bridge.batteryLeft
        updated.batteryRight = bridge.batteryRight
        updated.batteryCase = bridge.batteryCase
        updated.eqPreset = bridge.eqPreset
        updated.clearBass = bridge.clearBass
        updated.dsee = bridge.dsee
        updated.eqBands = (0..<5).map { bridge.equalizerBand(at: $0) }
        updated.hasAutoPowerOff = bridge.hasAutoPowerOff
        updated.autoPowerOff = bridge.autoPowerOff
        updated.firmware = bridge.firmware ?? ""
        updated.codec = bridge.codec ?? ""
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
}
