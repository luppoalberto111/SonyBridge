import Foundation

/// App-state-only UI status for the connected headphones screen.
///
/// These values are never produced by the Bluetooth SDK; they track the app's
/// own connection/error status and are kept out of ``HeadphonesState`` (which
/// lives in the SonyBTKit package and describes device state).
public struct HeadphonesUIState: Sendable, Equatable {
    /// True while a connection attempt is in flight (drives the "Connecting…" UI).
    public var connecting = false

    /// The last user-facing error message, or nil when the most recent operation succeeded.
    public var errorMessage: String?

    public init(connecting: Bool = false, errorMessage: String? = nil) {
        self.connecting = connecting
        self.errorMessage = errorMessage
    }
}
