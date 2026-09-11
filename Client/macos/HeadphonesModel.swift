//
//  HeadphonesModel.swift
//  Actor: the single serial owner of the Obj-C++ HeadphonesBridge.
//

import Foundation

// The bridge funnels every command through its own internal serial queue and
// only ever touches its C++ core from there, so sharing it with the actor is
// sound. It cannot be marked Sendable in Obj-C, hence the unchecked conformance.
extension HeadphonesBridge: @unchecked Sendable {}

/// Serial owner of the bridge. All bridge completion handlers are wrapped in
/// continuations; bridge values are snapshotted inside the handler (whatever
/// thread it runs on) and merged into actor state after the await, so no
/// isolated state ever escapes. Every method returns an immutable
/// `HeadphonesState` snapshot for the store to publish.
actor HeadphonesModel {
    private let bridge = HeadphonesBridge()
    private var state = HeadphonesState()

    var snapshot: HeadphonesState { state }

    // MARK: Connection

    func connect() async -> HeadphonesState {
        state.connecting = true
        state.errorMessage = nil
        let bridge = self.bridge
        // The native picker must run on the main thread and blocks it while
        // open. Dispatching async (rather than sync) lets the store's
        // "Connecting…" state paint before the modal appears.
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                bridge.scanAndConnect { ok, error in
                    continuation.resume(returning: (ok, error))
                }
            }
        }
        state.connecting = false
        if outcome.ok {
            syncFromBridge()
        } else if let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    func disconnect() async -> HeadphonesState {
        let bridge = self.bridge
        await MainActor.run { bridge.disconnect() }
        state.connected = false
        state.deviceName = ""
        return state
    }

    /// Timer-driven watchdog: the headset can drop RFCOMM on its own
    /// (idle power-save), so the UI must not show a stale "Connected".
    func pollConnection() async -> HeadphonesState {
        let bridge = self.bridge
        let connected = await MainActor.run { bridge.connected }
        if state.connected && !connected {
            state.connected = false
            state.deviceName = ""
            state.errorMessage = "Headphones disconnected."
        }
        return state
    }

    // MARK: Reads

    /// Runs the init handshake (once) then reads battery + equalizer.
    func refreshStatus() async -> HeadphonesState {
        let bridge = self.bridge
        let fresh: HeadphonesState = await withCheckedContinuation { continuation in
            bridge.refreshStatus {
                var s = HeadphonesState()
                s.batteryLevel = bridge.batteryLevel
                s.batteryCharging = bridge.batteryCharging
                s.hasDualBattery = bridge.hasDualBattery
                s.batteryLeft = bridge.batteryLeft
                s.batteryRight = bridge.batteryRight
                s.batteryCase = bridge.batteryCase
                s.eqPreset = bridge.eqPreset
                s.clearBass = bridge.clearBass
                s.dsee = bridge.dsee
                s.eqBands = (0..<5).map { bridge.equalizerBand(at: $0) }
                s.hasAutoPowerOff = bridge.hasAutoPowerOff
                s.autoPowerOff = bridge.autoPowerOff
                s.firmware = bridge.firmware ?? ""
                s.codec = bridge.codec ?? ""
                s.hasSpeakToChat = bridge.hasSpeakToChat
                s.speakToChat = bridge.speakToChat
                s.hasAdaptiveVolume = bridge.hasAdaptiveVolume
                s.adaptiveVolume = bridge.adaptiveVolume
                continuation.resume(returning: s)
            }
        }
        state.batteryLevel = fresh.batteryLevel
        state.batteryCharging = fresh.batteryCharging
        state.hasDualBattery = fresh.hasDualBattery
        state.batteryLeft = fresh.batteryLeft
        state.batteryRight = fresh.batteryRight
        state.batteryCase = fresh.batteryCase
        state.eqPreset = fresh.eqPreset
        state.clearBass = fresh.clearBass
        state.dsee = fresh.dsee
        state.eqBands = fresh.eqBands
        state.hasAutoPowerOff = fresh.hasAutoPowerOff
        state.autoPowerOff = fresh.autoPowerOff
        state.firmware = fresh.firmware
        state.codec = fresh.codec
        state.hasSpeakToChat = fresh.hasSpeakToChat
        state.speakToChat = fresh.speakToChat
        state.hasAdaptiveVolume = fresh.hasAdaptiveVolume
        state.adaptiveVolume = fresh.adaptiveVolume
        return state
    }

    /// Re-reads the fast-changing state (ambient/NC, level, EQ, DSEE) so
    /// changes made with the headphone's own button show up in the app.
    func refreshDynamic() async -> HeadphonesState {
        guard state.connected else { return state }
        let bridge = self.bridge
        let fresh: HeadphonesState = await withCheckedContinuation { continuation in
            bridge.refreshDynamic {
                var s = HeadphonesState()
                s.mode = bridge.mode
                s.ambientLevel = bridge.ambientLevel
                s.eqPreset = bridge.eqPreset
                s.clearBass = bridge.clearBass
                s.dsee = bridge.dsee
                s.eqBands = (0..<5).map { bridge.equalizerBand(at: $0) }
                continuation.resume(returning: s)
            }
        }
        state.mode = fresh.mode
        if fresh.ambientLevel > 0 { state.ambientLevel = fresh.ambientLevel }
        state.eqPreset = fresh.eqPreset
        state.clearBass = fresh.clearBass
        state.dsee = fresh.dsee
        state.eqBands = fresh.eqBands
        return state
    }

    // MARK: Ambient sound control

    func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState {
        state.mode = newMode
        return await pushAmbient()
    }

    func setLevel(_ level: Int) async -> HeadphonesState {
        state.ambientLevel = level
        if state.mode == .ambientSound {
            return await pushAmbient()
        }
        return state
    }

    func setFocusOnVoice(_ on: Bool) async -> HeadphonesState {
        state.focusOnVoice = on
        return await pushAmbient()
    }

    // MARK: Equalizer / DSEE

    func setEqualizer(_ preset: Int) async -> HeadphonesState {
        state.eqPreset = preset
        state.errorMessage = nil
        let bridge = self.bridge
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.setEqualizerPreset(preset) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if !outcome.ok, let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    /// Manual EQ (preset byte 0xA0 = 160).
    func setCustomEq(bass: Int, bands: [Int]) async -> HeadphonesState {
        state.eqPreset = 0xA0
        state.clearBass = bass
        state.eqBands = bands
        state.errorMessage = nil
        let bridge = self.bridge
        let numbers = bands.map { NSNumber(value: $0) }
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.setCustomEqualizerBass(bass, bands: numbers) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if !outcome.ok, let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    func setDsee(_ on: Bool) async -> HeadphonesState {
        state.dsee = on
        state.errorMessage = nil
        let bridge = self.bridge
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.setDsee(on) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if !outcome.ok, let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    // MARK: Optional features

    func setAutoPowerOff(_ index: Int) async -> HeadphonesState {
        state.autoPowerOff = index
        state.errorMessage = nil
        let bridge = self.bridge
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.setAutoPowerOff(index) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if !outcome.ok, let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    func setSpeakToChat(_ on: Bool) async -> HeadphonesState {
        state.speakToChat = on
        state.errorMessage = nil
        let bridge = self.bridge
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.setSpeakToChat(on) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if !outcome.ok, let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    func setAdaptiveVolume(_ on: Bool) async -> HeadphonesState {
        state.adaptiveVolume = on
        state.errorMessage = nil
        let bridge = self.bridge
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.setAdaptiveVolume(on) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if !outcome.ok, let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    // MARK: Private helpers (actor-isolated)

    private func pushAmbient() async -> HeadphonesState {
        let bridge = self.bridge
        let mode = state.mode
        let level = state.ambientLevel
        let focusVoice = state.focusOnVoice
        state.errorMessage = nil
        let outcome: (ok: Bool, error: String?) = await withCheckedContinuation { continuation in
            bridge.applyMode(mode, level: level, focusVoice: focusVoice) { ok, error in
                continuation.resume(returning: (ok, error))
            }
        }
        if outcome.ok {
            syncFromBridge()
        } else if let error = outcome.error {
            state.errorMessage = error
        }
        return state
    }

    private func syncFromBridge() {
        state.connected = bridge.connected
        state.deviceName = bridge.deviceName ?? ""
        state.deviceMac = bridge.deviceMac ?? ""
        state.protocolVersion = bridge.protocolVersionString ?? ""
        state.supportsVpt = bridge.supportsVpt
        state.supportsEqualizer = bridge.supportsEqualizer
        state.maxAmbientLevel = bridge.maxAmbientLevel
        state.mode = bridge.mode
        let level = bridge.ambientLevel
        if level > 0 { state.ambientLevel = level }
        state.focusOnVoice = bridge.focusOnVoice
        state.focusOnVoiceAvailable = bridge.focusOnVoiceAvailable
    }
}
