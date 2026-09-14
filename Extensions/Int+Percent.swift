import Foundation

extension Int {
    /// Locale-aware percent string (e.g. 80 becomes "80%").
    /// Uses a percent-style `NumberFormatter` so the placement and spacing of
    /// the percent sign follow the user's locale, instead of hardcoding
    /// a "%d%%" format that is wrong in some languages.
    var percentFormatted: String {
        Self.percentFormatter.string(from: NSNumber(value: Double(self) / 100)) ?? "\(self)%"
    }

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
