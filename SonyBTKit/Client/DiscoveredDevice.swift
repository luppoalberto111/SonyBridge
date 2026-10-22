import Foundation

/// A paired Bluetooth headset offered for connecting.
public struct DiscoveredDevice: Sendable, Hashable, Identifiable {
    /// The headset's advertised name, as reported by macOS.
    public let name: String

    /// Colon-separated lowercase MAC address, e.g. "94:65:2d:1a:7c:01".
    public let address: String

    /// The list identity, the MAC address (unique per paired device).
    public var id: String { address }

    /// Creates a device entry.
    ///
    /// - Parameters:
    ///   - name: The headset's display name.
    ///   - address: The colon-separated MAC address used to open the connection.
    public init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
