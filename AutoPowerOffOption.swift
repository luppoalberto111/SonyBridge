import Foundation

enum AutoPowerOffOption: Int, CaseIterable, Identifiable {
    case off = 0
    case fiveMinutes = 1
    case thirtyMinutes = 2
    case oneHour = 3
    case threeHours = 4
    case whenTakenOff = 5

    var id: Int {
        rawValue
    }

    var label: String {
        switch self {
            case .off: String(localized: "AutoPowerOff.off", defaultValue: "Off")
            case .fiveMinutes: String(localized: "AutoPowerOff.fiveMinutes", defaultValue: "5 min")
            case .thirtyMinutes: String(localized: "AutoPowerOff.thirtyMinutes", defaultValue: "30 min")
            case .oneHour: String(localized: "AutoPowerOff.oneHour", defaultValue: "1 hour")
            case .threeHours: String(localized: "AutoPowerOff.threeHours", defaultValue: "3 hours")
            case .whenTakenOff: String(localized: "AutoPowerOff.whenTakenOff", defaultValue: "When taken off")
        }
    }
}
