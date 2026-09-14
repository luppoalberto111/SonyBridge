import Foundation

/// A paired Bluetooth headset offered for connecting.
public struct DiscoveredDevice: Sendable, Hashable, Identifiable {
    public let name: String
    public let address: String

    public var id: String { address }

    public init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
