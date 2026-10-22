import Bridge
import Foundation

/// Public interface of the headphones client actor.
///
/// Mirrors every public method of ``HeadphonesClient`` so the app (and tests)
/// can depend on the abstraction instead of the concrete actor.
///
/// Every method is `async` because the underlying Bluetooth I/O blocks, and every one returns the
/// full ``HeadphonesState`` snapshot to render, so a reducer needs exactly one `await` per user
/// action.
public protocol HeadphonesClientProtocol: Sendable {
    // MARK: Connection

    /// Paired Sony-looking headsets available for connecting.
    ///
    /// - Returns: Devices with a display name and MAC address; empty when none match.
    func pairedDevices() async -> [DiscoveredDevice]

    /// Connects to the already system-connected Sony headset, if any.
    /// A non-connected state with no error means "nothing found".
    ///
    /// - Returns: The updated snapshot; the caller distinguishes "nothing found" (still disconnected,
    ///            no `errorMessage`) from a real failure (non-nil `errorMessage`).
    func connectToAutoDevice() async -> HeadphonesState

    /// Connects to the paired device with the given Bluetooth address.
    ///
    /// - Parameter address: Colon-separated MAC address, as returned by ``pairedDevices()``.
    /// - Returns: The updated snapshot, with `connected` and the capability flags set on success, or
    ///            `errorMessage` filled with user-facing copy on failure.
    func connect(address: String) async -> HeadphonesState

    /// Closes the connection and clears the device name.
    ///
    /// - Returns: The disconnected snapshot.
    func disconnect() async -> HeadphonesState

    /// Timer-driven watchdog: the headset can drop RFCOMM on its own
    /// (idle power-save), so the UI must not show a stale "Connected".
    ///
    /// - Returns: The snapshot, marked disconnected (with an `errorMessage`) when the link vanished.
    func pollConnection() async -> HeadphonesState

    // MARK: Reads

    /// Runs the init handshake (once) then reads battery + equalizer.
    ///
    /// - Returns: A snapshot with battery, equalizer and DSEE merged in.
    func refreshStatus() async -> HeadphonesState

    /// Runs the slow optional-feature probes; call after refreshStatus so the
    /// UI updates in two stages (fast values first, capabilities once settled).
    ///
    /// - Returns: A snapshot with the optional-feature flags (`has…`) merged in.
    func probeCapabilities() async -> HeadphonesState

    /// Re-reads the fast-changing state (ambient/NC, level, EQ, DSEE) so
    /// changes made with the headphone's own button show up in the app.
    ///
    /// - Returns: The refreshed snapshot; unchanged when not connected.
    func refreshDynamic() async -> HeadphonesState

    // MARK: Ambient sound control

    /// Switches between noise cancelling, ambient sound and off.
    ///
    /// - Parameter newMode: The `SHCAmbientMode` to apply.
    /// - Returns: The snapshot re-synced from the device, or with `errorMessage` set.
    func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState

    /// Sets the ambient-sound level (only written to the device while ambient mode is active).
    ///
    /// - Parameter level: 1...`maxAmbientLevel`; 0 means "no ambient sound".
    /// - Returns: The updated snapshot.
    func setLevel(_ level: Int) async -> HeadphonesState

    /// Toggles focus on voice (ambient sound emphasises voices).
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The snapshot re-synced from the device, or with `errorMessage` set.
    func setFocusOnVoice(_ on: Bool) async -> HeadphonesState

    // MARK: Equalizer / DSEE

    /// Selects an equalizer preset (raw preset byte; v2 devices only).
    ///
    /// - Parameter preset: The raw `EQ_PRESET` byte, e.g. `EqPreset.excited.rawValue`.
    /// - Returns: The updated snapshot, or with `errorMessage` set.
    func setEqualizer(_ preset: Int) async -> HeadphonesState

    /// Manual EQ (preset byte 0xA0 = 160).
    /// Pushes a custom equalizer curve and selects the MANUAL preset.
    ///
    /// - Parameters:
    ///   - bass: Clear-bass boost in -10...10.
    ///   - bands: The 5 frequency-band gains in -10...10.
    /// - Returns: The updated snapshot, or with `errorMessage` set.
    func setCustomEq(bass: Int, bands: [Int]) async -> HeadphonesState

    /// Toggles DSEE / audio upsampling (v2 devices only).
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The updated snapshot, or with `errorMessage` set.
    func setDsee(_ on: Bool) async -> HeadphonesState

    // MARK: Optional features

    /// Sets the auto-power-off delay.
    ///
    /// - Parameter index: 0=Off, 1=5 min, 2=30 min, 3=1 hour, 4=3 hours, 5=when taken off.
    /// - Returns: The updated snapshot, or with `errorMessage` set.
    func setAutoPowerOff(_ index: Int) async -> HeadphonesState

    /// Toggles speak-to-chat.
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The updated snapshot, or with `errorMessage` set.
    func setSpeakToChat(_ on: Bool) async -> HeadphonesState

    /// Toggles adaptive volume.
    ///
    /// - Parameter on: True to enable, false to disable.
    /// - Returns: The updated snapshot, or with `errorMessage` set.
    func setAdaptiveVolume(_ on: Bool) async -> HeadphonesState
}
