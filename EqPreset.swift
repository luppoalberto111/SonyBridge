import Foundation

enum EqPreset: Int, CaseIterable, Identifiable {
    case off = 0x00
    case bright = 0x10
    case excited = 0x11
    case mellow = 0x12
    case relaxed = 0x13
    case vocal = 0x14
    case treble = 0x15
    case bass = 0x16
    case speech = 0x17
    case manual = 0xA0
    
    var id: Int {
        rawValue
    }
    
    var name: String {
        switch self {
            case .off: String(localized: "EqPreset.off", defaultValue: "Off")
            case .bright: String(localized: "EqPreset.bright", defaultValue: "Bright")
            case .excited: String(localized: "EqPreset.excited", defaultValue: "Excited")
            case .mellow: String(localized: "EqPreset.mellow", defaultValue: "Mellow")
            case .relaxed: String(localized: "EqPreset.relaxed", defaultValue: "Relaxed")
            case .vocal: String(localized: "EqPreset.vocal", defaultValue: "Vocal")
            case .treble: String(localized: "EqPreset.treble", defaultValue: "Treble")
            case .bass: String(localized: "EqPreset.bass", defaultValue: "Bass")
            case .speech: String(localized: "EqPreset.speech", defaultValue: "Speech")
            case .manual: String(localized: "EqPreset.manual", defaultValue: "Manual")
        }
    }
}
