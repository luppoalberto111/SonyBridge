import Foundation

enum EqBand: Int, CaseIterable, Identifiable {
    case hz400 = 0
    case khz1 = 1
    case khz2_5 = 2
    case khz6_3 = 3
    case khz16 = 4

    var id: Int {
        rawValue
    }

    var label: String {
        switch self {
            case .hz400: "400"
            case .khz1: "1k"
            case .khz2_5: "2.5k"
            case .khz6_3: "6.3k"
            case .khz16: "16k"
        }
    }
}
