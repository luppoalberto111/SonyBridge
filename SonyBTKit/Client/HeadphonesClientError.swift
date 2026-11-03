import Foundation

/// An error reported by ``HeadphonesClient`` / ``HeadphonesTestClient`` when a
/// Bluetooth command fails.
public struct HeadphonesClientError: Error, LocalizedError, Sendable {
    /// The user-facing failure message.
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}
