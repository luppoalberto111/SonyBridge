@testable import SonyHeadphonesClient
import Testing

struct IntPercentTests {
    @Test func formatsWholePercent() {
        #expect(80.percentFormatted == "80%")
    }

    @Test func formatsZeroPercent() {
        #expect(0.percentFormatted == "0%")
    }

    @Test func formatsFullPercent() {
        #expect(100.percentFormatted == "100%")
    }
}
