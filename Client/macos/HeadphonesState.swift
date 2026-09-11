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
