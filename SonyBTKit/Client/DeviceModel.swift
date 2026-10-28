import DeveloperToolsSupport
import Either
import SwiftUI

// MARK: - DeviceModel

/// A headset model the app recognises from its advertised Bluetooth name.
///
/// The raw value is the stock marketing name, which is also what Sony headsets advertise,
/// so ``DeviceModel/init(rawValue:)`` resolves a model without any string manipulation.
/// Headsets that don't match (renamed or unsupported devices) are represented by the right
/// case of ``Either`` instead.
public enum DeviceModel: String, CaseIterable, Sendable {
    case linkBudsS = "LinkBuds S"
    case mdrXb950Bt = "MDR-XB950BT"
    case wf1000Xm4 = "WF-1000XM4"
    case wf1000Xm5 = "WF-1000XM5"
    case wfC700N = "WF-C700N"
    case wfC710N = "WF-C710N"
    case wh1000Xm2 = "WH-1000XM2"
    case wh1000Xm3 = "WH-1000XM3"
    case wh1000Xm4 = "WH-1000XM4"
    case wh1000Xm5 = "WH-1000XM5"
    case wh1000Xm6 = "WH-1000XM6"
    case whCh520 = "WH-CH520"
    case whCh720N = "WH-CH720N"
    case whXb900N = "WH-XB900N"
    case whXb910N = "WH-XB910N"

    /// Hero artwork for the model, from the Client target's asset catalog.
    ///
    /// Uses the generated asset symbols, so adding a model without artwork fails to compile.
    public var image: Image {
        switch self {
            case .linkBudsS: Image(.linkbudsS)
            case .mdrXb950Bt: Image(.mdrXb950Bt)
            case .wf1000Xm4: Image(.wf1000Xm4)
            case .wf1000Xm5: Image(.wf1000Xm5)
            case .wfC700N: Image(.wfC700N)
            case .wfC710N: Image(.wfC710N)
            case .wh1000Xm2: Image(.wh1000Xm2)
            case .wh1000Xm3: Image(.wh1000Xm3)
            case .wh1000Xm4: Image(.wh1000Xm4)
            case .wh1000Xm5: Image(.wh1000Xm5)
            case .wh1000Xm6: Image(.wh1000Xm6)
            case .whCh520: Image(.whCh520)
            case .whCh720N: Image(.whCh720N)
            case .whXb900N: Image(.whXb900N)
            case .whXb910N: Image(.whXb910N)
        }
    }
}
