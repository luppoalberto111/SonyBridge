import Bridge
import Foundation

/// In-memory test double for ``HeadphonesClientProtocol``.
///
/// Mirrors the real client's state transitions without touching Bluetooth,
/// so tests and previews can drive deterministic scenarios by seeding
/// `state` up front and asserting on it afterwards.
public actor HeadphonesTestClient: HeadphonesClientProtocol {
    /// The snapshot handed back by every method; seed it to set up a scenario, assert on it to check
    /// what the reducer did.
    public var state: HeadphonesState

    /// Devices returned by `pairedDevices()`.
    public var stubbedDevices: [DiscoveredDevice] = []

    /// When set, `connect(address:)` fails with this message instead of connecting.
    public var connectionError: String?

    /// When false, ``connectToAutoDevice()`` simulates finding no system-connected headset.
    public var autoConnectSucceeds = true

    /// Creates a test client with an optional pre-seeded snapshot.
    ///
    /// - Parameter state: The initial ``HeadphonesState``; defaults to an empty (disconnected) one.
    public init(state: HeadphonesState = HeadphonesState()) {
        self.state = state
    }

    /// Replaces the devices reported by ``pairedDevices()``.
    ///
    /// - Parameter devices: The device list to return from now on.
    public func setStubbedDevices(_ devices: [DiscoveredDevice]) {
        stubbedDevices = devices
    }

    /// Makes connection attempts fail, to exercise the error UI.
    ///
    /// - Parameter message: A user-facing failure message, or nil to restore the success path.
    public func setConnectionError(_ message: String?) {
        connectionError = message
    }

    /// Controls whether ``connectToAutoDevice()`` simulates finding a device.
    ///
    /// - Parameter value: False to exercise the "no auto-connectable device" path.
    public func setAutoConnectSucceeds(_ value: Bool) {
        autoConnectSucceeds = value
    }

    // MARK: Connection

    /// Returns the seeded device list.
    ///
    /// - Returns: Whatever was passed to ``setStubbedDevices(_:)``; empty by default.
    public func pairedDevices() async -> [DiscoveredDevice] {
        stubbedDevices
    }

    /// Simulates an auto-connect attempt.
    ///
    /// - Returns: The snapshot with `connected` true when ``autoConnectSucceeds`` is true;
    ///            otherwise the unchanged (disconnected) snapshot.
    public func connectToAutoDevice() async -> HeadphonesState {
        state.connecting = false
        state.errorMessage = nil
        if autoConnectSucceeds {
            state.connected = true
        }
        return state
    }

    /// Simulates connecting to a specific address.
    ///
    /// Fails with `connectionError` when one was set; otherwise looks the address up in
    /// `stubbedDevices` to fill in the name and MAC.
    ///
    /// - Parameter address: The MAC address the caller asked to connect to.
    /// - Returns: The connected snapshot, or the unchanged one with `errorMessage` set on failure.
    public func connect(address: String) async -> HeadphonesState {
        state.connecting = false
        state.errorMessage = nil
        if let connectionError {
            state.errorMessage = connectionError
            return state
        }
        if let device = stubbedDevices.first(where: { $0.address == address }) {
            state.deviceName = device.name
            state.deviceMac = device.address
        }
        state.connected = true
        return state
    }

    /// Simulates disconnecting.
    ///
    /// - Returns: The snapshot with `connected` false and an empty `deviceName`.
    public func disconnect() async -> HeadphonesState {
        state.connected = false
        state.deviceName = ""
        return state
    }

    /// Simulates the connection watchdog; never changes state (no Bluetooth link to lose).
    ///
    /// - Returns: The current snapshot, unchanged.
    public func pollConnection() async -> HeadphonesState {
        state
    }

    // MARK: Reads

    /// Simulates the first-stage status read; no device is queried.
    ///
    /// - Returns: The current snapshot, unchanged.
    public func refreshStatus() async -> HeadphonesState {
        state
    }

    /// Simulates the capability probes; no device is queried.
    ///
    /// - Returns: The current snapshot, unchanged.
    public func probeCapabilities() async -> HeadphonesState {
        state
    }

    /// Simulates the dynamic poll; no device is queried.
    ///
    /// - Returns: The current snapshot, unchanged.
    public func refreshDynamic() async -> HeadphonesState {
        state
    }

    // MARK: Ambient sound control

    /// Applies a mode change locally, like the real client but without the Bluetooth write.
    ///
    /// - Parameter newMode: The `SHCAmbientMode` stored in the snapshot.
    /// - Returns: The updated snapshot.
    public func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState {
        state.mode = newMode
        return state
    }

    /// Applies an ambient-level change locally.
    ///
    /// - Parameter level: The level stored in the snapshot, 1...`maxAmbientLevel`.
    /// - Returns: The updated snapshot.
    public func setLevel(_ level: Int) async -> HeadphonesState {
        state.ambientLevel = level
        return state
    }

    /// Applies a focus-on-voice change locally.
    ///
    /// - Parameter on: The flag stored in the snapshot.
    /// - Returns: The updated snapshot.
    public func setFocusOnVoice(_ on: Bool) async -> HeadphonesState {
        state.focusOnVoice = on
        return state
    }

    // MARK: Equalizer / DSEE

    /// Applies an equalizer preset change locally.
    ///
    /// - Parameter preset: The raw preset byte stored in the snapshot.
    /// - Returns: The updated snapshot with `errorMessage` cleared.
    public func setEqualizer(_ preset: Int) async -> HeadphonesState {
        state.eqPreset = preset
        state.errorMessage = nil
        return state
    }

    /// Applies a custom equalizer curve locally, selecting the MANUAL preset.
    ///
    /// - Parameters:
    ///   - bass: Clear-bass boost in -10...10.
    ///   - bands: The 5 band gains in -10...10.
    /// - Returns: The updated snapshot with `eqPreset == 0xA0`.
    public func setCustomEq(bass: Int, bands: [Int]) async -> HeadphonesState {
        state.eqPreset = 0xA0
        state.clearBass = bass
        state.eqBands = bands
        state.errorMessage = nil
        return state
    }

    /// Applies a DSEE change locally.
    ///
    /// - Parameter on: The flag stored in the snapshot.
    /// - Returns: The updated snapshot with `errorMessage` cleared.
    public func setDsee(_ on: Bool) async -> HeadphonesState {
        state.dsee = on
        state.errorMessage = nil
        return state
    }

    // MARK: Optional features

    /// Applies an auto-power-off selection locally.
    ///
    /// - Parameter index: The delay index stored in the snapshot, 0...5.
    /// - Returns: The updated snapshot with `errorMessage` cleared.
    public func setAutoPowerOff(_ index: Int) async -> HeadphonesState {
        state.autoPowerOff = index
        state.errorMessage = nil
        return state
    }

    /// Applies a speak-to-chat change locally.
    ///
    /// - Parameter on: The flag stored in the snapshot.
    /// - Returns: The updated snapshot with `errorMessage` cleared.
    public func setSpeakToChat(_ on: Bool) async -> HeadphonesState {
        state.speakToChat = on
        state.errorMessage = nil
        return state
    }

    /// Applies an adaptive-volume change locally.
    ///
    /// - Parameter on: The flag stored in the snapshot.
    /// - Returns: The updated snapshot with `errorMessage` cleared.
    public func setAdaptiveVolume(_ on: Bool) async -> HeadphonesState {
        state.adaptiveVolume = on
        state.errorMessage = nil
        return state
    }
}
