import Either

extension Either where Left == DeviceModel, Right == String {
    /// Resolves a headset model from its advertised Bluetooth name.
    ///
    /// A name equal to a stock marketing name becomes the left case; anything else is kept
    /// verbatim in the right case.
    ///
    /// - Parameter deviceName: The name the headset advertises over Bluetooth.
    public init(deviceName: String) {
        self = DeviceModel(rawValue: deviceName).map { .left($0) } ?? .right(deviceName)
    }

    /// The name to show for the device: the stock model name when recognised, otherwise the
    /// advertised name unchanged.
    public var displayName: String {
        switch self {
            case let .left(model): model.rawValue
            case let .right(name): name
        }
    }
}
