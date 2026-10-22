import Bridge
import Foundation

/// Async, `Sendable` facade over ``HeadphonesBridge`` for the app's TCA reducers.
///
/// The actor serializes every access to the bridge, optimistically mirrors each change into its own
/// `HeadphonesState` snapshot and returns it, so a reducer can `await` one call and get the state to
/// render. State is only refreshed from the device on `refresh…`/`probe…` calls, never implicitly.
public actor HeadphonesClient: HeadphonesClientProtocol {
    /// Creates a client with its own bridge instance (and therefore its own connection).
    public init() {}

    private let bridge = HeadphonesBridge()
    private var state = HeadphonesState()

    // MARK: Connection

    /// Lists the paired Sony-looking headsets to offer in the manual device picker.
    ///
    /// Reads the system's paired Bluetooth devices and filters them by known Sony model prefixes.
    ///
    /// - Returns: Devices with a display name and a MAC address; empty when none match.
    public func pairedDevices() async -> [DiscoveredDevice] {
        let bridge = bridge
        let entries = await MainActor.run { bridge.pairedSonyDevices() }
        return entries.compactMap { entry in
            guard let name = entry["name"], let address = entry["address"] else { return nil }
            return DiscoveredDevice(name: name, address: address)
        }
    }

    // No UI is involved anymore; hopping to the main thread keeps all
    // IOBluetooth use on one thread and lets "Connecting…" paint first.
    /// Bridge call for ``connectToAutoDevice``, kept on the main actor so all IOBluetooth use stays on one thread.
    ///
    /// - Parameter bridge: The bridge to connect through.
    /// - Returns: `(ok, error)`; `(false, nil)` means no Sony device was found (not a failure).
    @MainActor
    private func connectToAutoDeviceOnMain(_ bridge: HeadphonesBridge) async -> (Bool, String?) {
        await bridge.connectToAutoDevice()
    }

    /// Bridge call for ``connect(address:)``, kept on the main actor for the same reason as above.
    ///
    /// - Parameters:
    ///   - bridge: The bridge to connect through.
    ///   - address: Colon-separated MAC address of the paired device to open.
    /// - Returns: `(ok, error)`; `error` is user-facing copy, nil on success.
    @MainActor private func connectToDeviceOnMain(
        _ bridge: HeadphonesBridge,
        address: String
    ) async -> (Bool, String?) {
        await bridge.connectToDevice(withAddress: address)
    }

    /// Connects to the Sony headset macOS already considers connected ("My Device" behaviour).
    ///
    /// Sets `connecting` while the (blocking) RFCOMM handshake runs, then syncs the connection
    /// properties on success.
    ///
    /// - Returns: The updated snapshot. Staying disconnected with no `errorMessage` means no Sony
    ///            device was found, and the caller should offer the device list.
    public func connectToAutoDevice() async -> HeadphonesState {
        state.connecting = true
        state.errorMessage = nil
        let (ok, error) = await connectToAutoDeviceOnMain(bridge)
        state.connecting = false
        if ok {
            state = state.synced(with: bridge)
        } else if let error {
            state.errorMessage = error
        }
        return state
    }

    /// Connects to a specific paired headset.
    ///
    /// - Parameter address: Colon-separated MAC address, as returned by ``pairedDevices()``.
    /// - Returns: The updated snapshot, with `connected`, `deviceName` and the capability flags
    ///            filled in on success, or `errorMessage` set with user-facing copy on failure.
    public func connect(address: String) async -> HeadphonesState {
        state.connecting = true
        state.errorMessage = nil
        let (ok, error) = await connectToDeviceOnMain(bridge, address: address)
        state.connecting = false
        if ok {
            state = state.synced(with: bridge)
        } else if let error {
            state.errorMessage = error
        }
        return state
    }

    /// Closes the connection and clears the device name.
    ///
    /// - Returns: The disconnected snapshot (`connected == false`, empty `deviceName`).
    public func disconnect() async -> HeadphonesState {
        let bridge = bridge
        await MainActor.run { bridge.disconnect() }
        state.connected = false
        state.deviceName = ""
        return state
    }

    // MARK: Reads

    /// Timer-driven watchdog: the headset can drop RFCOMM on its own
    /// (idle power-save), so the UI must not show a stale "Connected".
    /// Detects a connection the headset dropped on its own, for the app's 1.5 s connection watchdog.
    ///
    /// Asks the bridge whether the RFCOMM channel is still open and, if it vanished while the state
    /// said otherwise, marks the snapshot disconnected with an explanatory message.
    ///
    /// - Returns: The (possibly updated) snapshot; when `connected` became false the reducer cancels
    ///            its polling effects and pops back to the disconnected screen.
    public func pollConnection() async -> HeadphonesState {
        let bridge = bridge
        let connected = await MainActor.run { bridge.connected }
        if state.connected, !connected {
            state.connected = false
            state.deviceName = ""
            state.errorMessage = "Headphones disconnected."
        }
        return state
    }

    // MARK: Reads

    /// Runs the init handshake (once) then reads battery + equalizer.
    ///
    /// First stage of the post-connect refresh: fast, always-supported inquiries only. On v1 devices
    /// this issues read-only ambient traffic instead, because the v2 battery opcode would power them
    /// off. The blocking I/O happens on a background queue, so this doesn't hold up user taps.
    ///
    /// - Returns: A snapshot with battery, equalizer and DSEE merged in.
    public func refreshStatus() async -> HeadphonesState {
        await bridge.refreshStatus()
        return state.updated(with: bridge)
    }

    /// Runs the slow optional-feature probes; call after refreshStatus so the
    /// UI updates in two stages (fast values first, capabilities once settled).
    ///
    /// Second stage: firmware, codec, auto power off, adaptive volume and speak-to-chat. Each probe
    /// can take seconds to time out on devices that don't support the feature, so unsupported ones
    /// simply keep their `has… == false` flags.
    ///
    /// - Returns: A snapshot with the optional-feature flags merged in.
    public func probeCapabilities() async -> HeadphonesState {
        await bridge.probeCapabilities()
        return state.updated(with: bridge)
    }

    /// Re-reads the fast-changing state (ambient/NC, level, EQ, DSEE) so
    /// changes made with the headphone's own button show up in the app.
    /// Also folds in the battery inquiry while still unknown: the inquiry
    /// only runs at connect and is best-effort, so without a retry a missed
    /// read stays empty forever. Never clobbers a known reading.
    /// Polls the state the headphone's own buttons can change, for the app's 2 s dynamic poll.
    ///
    /// Only runs while connected. An unknown ambient level (`0`) is ignored rather than applied, so a
    /// transient read doesn't fight the user's slider; battery is merged via
    /// ``HeadphonesState/mergeBattery(from:)``.
    ///
    /// - Returns: The refreshed snapshot.
    public func refreshDynamic() async -> HeadphonesState {
        guard state.connected else { return state }
        await bridge.refreshDynamic()
        state.mode = bridge.mode
        let level = bridge.ambientLevel
        if level > 0 { state.ambientLevel = level }
        state.eqPreset = bridge.eqPreset
        state.clearBass = bridge.clearBass
        state.dsee = bridge.dsee
        state.eqBands = (0 ..< 5).map { bridge.equalizerBand(at: $0) }
        state.mergeBattery(from: bridge)
        return state
    }

    // MARK: Ambient sound control

    /// Switches between noise cancelling, ambient sound and off.
    ///
    /// Optimistically stores the mode, then pushes the whole ambient trio (mode, level, focus on
    /// voice) in one device command.
    ///
    /// - Parameter newMode: The `SHCAmbientMode` to apply.
    /// - Returns: The snapshot re-synced from the device on success, or with `errorMessage` set.
    public func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState {
        state.mode = newMode
        return await pushAmbient()
    }

    /// Sets the ambient-sound level.
    ///
    /// Stores the level always (so the slider feels immediate), but only writes to the device when
    /// ambient sound mode is active — otherwise the value would be meaningless.
    ///
    /// - Parameter level: 1...`maxAmbientLevel` (19 on v1 devices, 20 on v2); 0 means "off".
    /// - Returns: The snapshot re-synced from the device when a command was sent, otherwise unchanged.
    public func setLevel(_ level: Int) async -> HeadphonesState {
        state.ambientLevel = level
        if state.mode == .ambientSound {
            return await pushAmbient()
        }
        return state
    }

    /// Toggles focus on voice (ambient sound emphasises voices).
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The snapshot re-synced from the device on success, or with `errorMessage` set.
    public func setFocusOnVoice(_ on: Bool) async -> HeadphonesState {
        state.focusOnVoice = on
        return await pushAmbient()
    }

    // MARK: Equalizer / DSEE

    /// Selects an equalizer preset on the device.
    ///
    /// - Parameter preset: The raw preset byte, e.g. one of `EqPreset`'s raw values (0x00 Off,
    ///   0x10…0x17 presets, 0xA0 Manual). v2 devices only; v1 reports an error.
    /// - Returns: The snapshot with `eqPreset` set, or with `errorMessage` if the write failed.
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
    /// Pushes a custom (manual) equalizer curve, selecting the MANUAL preset.
    ///
    /// Called on every slider tick, so the command queue serializes rapid successive writes.
    ///
    /// - Parameters:
    ///   - bass: Clear-bass boost in -10...10.
    ///   - bands: The 5 frequency-band gains in -10...10 (fewer entries are padded with 0 by the core).
    /// - Returns: The snapshot with `eqPreset == 0xA0` and the new values, or `errorMessage` on failure.
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

    /// Toggles DSEE (audio upsampling).
    ///
    /// - Parameter on: True to enable, false to disable. v2 devices only.
    /// - Returns: The snapshot with `dsee` set, or with `errorMessage` if the write failed.
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

    /// Sets the auto-power-off delay.
    ///
    /// - Parameter index: 0=Off, 1=5 min, 2=30 min, 3=1 hour, 4=3 hours, 5=when taken off (the raw
    ///   values of `AutoPowerOffOption`).
    /// - Returns: The snapshot with `autoPowerOff` set, or with `errorMessage` if the write failed.
    public func setAutoPowerOff(_ index: Int) async -> HeadphonesState {
        state.autoPowerOff = index
        state.errorMessage = nil
        let (ok, error) = await bridge.setAutoPowerOff(index)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    /// Toggles speak-to-chat (ambient mode when you start talking).
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The snapshot with `speakToChat` set, or with `errorMessage` if the write failed.
    public func setSpeakToChat(_ on: Bool) async -> HeadphonesState {
        state.speakToChat = on
        state.errorMessage = nil
        let (ok, error) = await bridge.setSpeakToChat(on)
        if !ok, let error {
            state.errorMessage = error
        }
        return state
    }

    /// Toggles adaptive volume (level follows the ambient loudness).
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The snapshot with `adaptiveVolume` set, or with `errorMessage` if the write failed.
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

    /// Sends the staged ambient trio (mode, level, focus on voice) as one device command.
    ///
    /// Reads the values from `state` first, because the await below suspends the actor. On success
    /// the snapshot is re-synced from the device so the UI shows what was actually applied; on
    /// failure only `errorMessage` is set, leaving the user's selection in place for a retry.
    ///
    /// - Returns: The resulting snapshot.
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
