import Bridge
import Foundation

/// In-memory test double for ``HeadphonesClientProtocol``.
///
/// Mirrors the real client's state transitions without touching Bluetooth,
/// so tests and previews can drive deterministic scenarios by seeding
/// `state` up front and asserting on it afterwards.
public actor HeadphonesTestClient: HeadphonesClientProtocol {
    public var state: HeadphonesState

    public init(state: HeadphonesState = HeadphonesState()) {
        self.state = state
    }

    // MARK: Connection

    public func connect() async -> HeadphonesState {
        state.connecting = false
        state.errorMessage = nil
        state.connected = true
        return state
    }

    public func disconnect() async -> HeadphonesState {
        state.connected = false
        state.deviceName = ""
        return state
    }

    public func pollConnection() async -> HeadphonesState {
        state
    }

    // MARK: Reads

    public func refreshStatus() async -> HeadphonesState {
        state
    }

    public func probeCapabilities() async -> HeadphonesState {
        state
    }

    public func refreshDynamic() async -> HeadphonesState {
        state
    }

    // MARK: Ambient sound control

    public func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState {
        state.mode = newMode
        return state
    }

    public func setLevel(_ level: Int) async -> HeadphonesState {
        state.ambientLevel = level
        return state
    }

    public func setFocusOnVoice(_ on: Bool) async -> HeadphonesState {
        state.focusOnVoice = on
        return state
    }

    // MARK: Equalizer / DSEE

    public func setEqualizer(_ preset: Int) async -> HeadphonesState {
        state.eqPreset = preset
        state.errorMessage = nil
        return state
    }

    public func setCustomEq(bass: Int, bands: [Int]) async -> HeadphonesState {
        state.eqPreset = 0xA0
        state.clearBass = bass
        state.eqBands = bands
        state.errorMessage = nil
        return state
    }

    public func setDsee(_ on: Bool) async -> HeadphonesState {
        state.dsee = on
        state.errorMessage = nil
        return state
    }

    // MARK: Optional features

    public func setAutoPowerOff(_ index: Int) async -> HeadphonesState {
        state.autoPowerOff = index
        state.errorMessage = nil
        return state
    }

    public func setSpeakToChat(_ on: Bool) async -> HeadphonesState {
        state.speakToChat = on
        state.errorMessage = nil
        return state
    }

    public func setAdaptiveVolume(_ on: Bool) async -> HeadphonesState {
        state.adaptiveVolume = on
        state.errorMessage = nil
        return state
    }
}
