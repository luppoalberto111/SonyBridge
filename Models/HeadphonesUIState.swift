import Foundation

/// App-state-only UI status for the connected headphones screen.
///
/// These values are never produced by the Bluetooth SDK; they track the app's
/// own connection/error status and are kept out of ``HeadphonesState`` (which
/// lives in the SonyBTKit package and describes device state).
public struct HeadphonesUIState: Sendable, Equatable {
    /// True while a connection attempt is in flight (drives the "Connecting…" UI).
    public var connecting: Bool

    /// True while a focus-on-voice change is in flight.
    ///
    /// The toggle stays disabled and keeps its previous value until the device confirms the write,
    /// so the UI never shows a value the headset hasn't acknowledged yet.
    public var focusOnVoiceLoading: Bool

    /// True while an adaptive-volume change is in flight.
    ///
    /// Like ``focusOnVoiceLoading``, the toggle stays disabled and keeps its confirmed value until
    /// the device acknowledges the write.
    public var adaptiveVolumeLoading: Bool

    /// True while an auto-power-off change is in flight.
    ///
    /// The picker stays disabled and keeps its confirmed value until the device acknowledges the
    /// write.
    public var autoPowerOffLoading: Bool

    /// True while a DSEE change is in flight.
    ///
    /// The toggle stays disabled and keeps its confirmed value until the device acknowledges the
    /// write.
    public var dseeLoading: Bool

    /// The last user-facing error message, or nil when the most recent operation succeeded.
    public var errorMessage: String?

    /// The EQ preset value currently shown in the UI.
    public var eqPreset = 0

    public init(
        connecting: Bool = false,
        focusOnVoiceLoading: Bool = false,
        adaptiveVolumeLoading: Bool = false,
        autoPowerOffLoading: Bool = false,
        dseeLoading: Bool = false,
        errorMessage: String? = nil,
        eqPreset: Int = 0
    ) {
        self.connecting = connecting
        self.focusOnVoiceLoading = focusOnVoiceLoading
        self.adaptiveVolumeLoading = adaptiveVolumeLoading
        self.autoPowerOffLoading = autoPowerOffLoading
        self.dseeLoading = dseeLoading
        self.errorMessage = errorMessage
        self.eqPreset = eqPreset
    }
}
