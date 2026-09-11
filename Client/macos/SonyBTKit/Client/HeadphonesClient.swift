import Foundation
import Bridge

/// Presents the native picker on the main thread by awaiting the bridge's
/// synthesized async overload from the main actor.

public actor HeadphonesClient {
    public init() {}

    private let bridge = HeadphonesBridge()
    private var state = HeadphonesState()

    // MARK: Connection

    @MainActor
    private func scanAndConnectOnMain(_ bridge: HeadphonesBridge) async -> (Bool, String?) {
        await bridge.scanAndConnect()
    }

    public func connect() async -> HeadphonesState {
        state.connecting = true
        state.errorMessage = nil
        // The native picker must run on the main thread and blocks it while
        // open; hopping to the main actor also lets the store's
        // "Connecting…" state paint before the modal appears.
        let (ok, error) = await scanAndConnectOnMain(bridge)
        state.connecting = false
        if ok {
            state = state.synced(with: bridge)
        } else if let error {
            state.errorMessage = error
        }
        return state
    }

    public func disconnect() async -> HeadphonesState {
        let bridge = self.bridge
        await MainActor.run { bridge.disconnect() }
        state.connected = false
        state.deviceName = ""
        return state
    }

    /// Timer-driven watchdog: the headset can drop RFCOMM on its own
    /// (idle power-save), so the UI must not show a stale "Connected".
    public func pollConnection() async -> HeadphonesState {
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
    public func refreshStatus() async -> HeadphonesState {
        await bridge.refreshStatus()
        return state.updated(with: bridge)
    }

    /// Runs the slow optional-feature probes; call after refreshStatus so the
    /// UI updates in two stages (fast values first, capabilities once settled).
    public func probeCapabilities() async -> HeadphonesState {
        await bridge.probeCapabilities()
        return state.updated(with: bridge)
    }

    /// Re-reads the fast-changing state (ambient/NC, level, EQ, DSEE) so
    /// changes made with the headphone's own button show up in the app.
    public func refreshDynamic() async -> HeadphonesState {
        guard state.connected else { return state }
        await bridge.refreshDynamic()
        state.mode = bridge.mode
        let level = bridge.ambientLevel
        if level > 0 { state.ambientLevel = level }
        state.eqPreset = bridge.eqPreset
        state.clearBass = bridge.clearBass
        state.dsee = bridge.dsee
        state.eqBands = (0..<5).map { bridge.equalizerBand(at: $0) }
        return state
    }

    // MARK: Ambient sound control

    public func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState {
        state.mode = newMode
        return await pushAmbient()
    }

    public func setLevel(_ level: Int) async -> HeadphonesState {
        state.ambientLevel = level
        if state.mode == .ambientSound {
            return await pushAmbient()
        }
        return state
    }

    public func setFocusOnVoice(_ on: Bool) async -> HeadphonesState {
        state.focusOnVoice = on
        return await pushAmbient()
    }

    // MARK: Equalizer / DSEE

    public func setEqualizer(_ preset: Int) async -> HeadphonesState {
        state.eqPreset = preset
        state.errorMessage = nil
        let (ok, error) = await bridge.setEqualizerPreset(preset)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    /// Manual EQ (preset byte 0xA0 = 160).
    public func setCustomEq(bass: Int, bands: [Int]) async -> HeadphonesState {
        state.eqPreset = 0xA0
        state.clearBass = bass
        state.eqBands = bands
        state.errorMessage = nil
        let numbers = bands.map { NSNumber(value: $0) }
        let (ok, error) = await bridge.setCustomEqualizerBass(bass, bands: numbers)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    public func setDsee(_ on: Bool) async -> HeadphonesState {
        state.dsee = on
        state.errorMessage = nil
        let (ok, error) = await bridge.setDsee(on)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    // MARK: Optional features

    public func setAutoPowerOff(_ index: Int) async -> HeadphonesState {
        state.autoPowerOff = index
        state.errorMessage = nil
        let (ok, error) = await bridge.setAutoPowerOff(index)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    public func setSpeakToChat(_ on: Bool) async -> HeadphonesState {
        state.speakToChat = on
        state.errorMessage = nil
        let (ok, error) = await bridge.setSpeakToChat(on)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    public func setAdaptiveVolume(_ on: Bool) async -> HeadphonesState {
        state.adaptiveVolume = on
        state.errorMessage = nil
        let (ok, error) = await bridge.setAdaptiveVolume(on)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    // MARK: Private helpers (actor-isolated)

    private func pushAmbient() async -> HeadphonesState {
        let mode = state.mode
        let level = state.ambientLevel
        let focusVoice = state.focusOnVoice
        state.errorMessage = nil
        let (ok, error) = await bridge.applyMode(mode, level: level, focusVoice: focusVoice)
        if ok {
            state = state.synced(with: bridge)
        } else if let error {
            state.errorMessage = error
        }
        return state
    }
}
