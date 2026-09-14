import Foundation
import Bridge

/// Public interface of the headphones client actor.
///
/// Mirrors every public method of ``HeadphonesClient`` so the app (and tests)
/// can depend on the abstraction instead of the concrete actor.
public protocol HeadphonesClientProtocol: Sendable {
    // MARK: Connection

    func connect() async -> HeadphonesState
    func disconnect() async -> HeadphonesState

    /// Timer-driven watchdog: the headset can drop RFCOMM on its own
    /// (idle power-save), so the UI must not show a stale "Connected".
    func pollConnection() async -> HeadphonesState

    // MARK: Reads

    /// Runs the init handshake (once) then reads battery + equalizer.
    func refreshStatus() async -> HeadphonesState

    /// Runs the slow optional-feature probes; call after refreshStatus so the
    /// UI updates in two stages (fast values first, capabilities once settled).
    func probeCapabilities() async -> HeadphonesState

    /// Re-reads the fast-changing state (ambient/NC, level, EQ, DSEE) so
    /// changes made with the headphone's own button show up in the app.
    func refreshDynamic() async -> HeadphonesState

    // MARK: Ambient sound control

    func setMode(_ newMode: SHCAmbientMode) async -> HeadphonesState
    func setLevel(_ level: Int) async -> HeadphonesState
    func setFocusOnVoice(_ on: Bool) async -> HeadphonesState

    // MARK: Equalizer / DSEE

    func setEqualizer(_ preset: Int) async -> HeadphonesState

    /// Manual EQ (preset byte 0xA0 = 160).
    func setCustomEq(bass: Int, bands: [Int]) async -> HeadphonesState
    func setDsee(_ on: Bool) async -> HeadphonesState

    // MARK: Optional features

    func setAutoPowerOff(_ index: Int) async -> HeadphonesState
    func setSpeakToChat(_ on: Bool) async -> HeadphonesState
    func setAdaptiveVolume(_ on: Bool) async -> HeadphonesState
}
