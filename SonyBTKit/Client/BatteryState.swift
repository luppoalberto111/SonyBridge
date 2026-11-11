import Foundation
import SwiftUI

/// The battery buckets the UI renders, derived from a percentage and a charging flag.
public enum BatteryState: Hashable {
    /// 15 % or less.
    case empty
    /// 16–50 %.
    case half
    /// More than 50 %.
    case full
    /// Plugged in / charging, whatever the percentage is.
    case charging

    /// Buckets a raw battery percentage into one of the displayable states.
    ///
    /// - Parameters:
    ///   - rawValue: The percentage, 0...100; negative (unknown) buckets as `.full` since it never
    ///               reaches a level read.
    ///   - isCharging: When true the state is `.charging` regardless of `rawValue`.
    public init(rawValue: Int, isCharging: Bool) {
        if isCharging {
            self = .charging
            return
        }
        self = switch rawValue {
            case ...15:
                .empty
            case ...50:
                .half
            default:
                .full
        }
    }

    /// The SF Symbol name for this state, so the view can build an `Image` directly.
    public var image: Image {
        let systemName = switch self {
            case .empty:
                "battery.0"
            case .half:
                "battery.25"
            case .full:
                "battery.100"
            case .charging:
                "bolt.fill"
        }
        return Image(systemName: systemName)
    }
}
