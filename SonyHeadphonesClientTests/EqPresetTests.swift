import Testing

@testable import SonyHeadphonesClient

// MARK: - EqPresetTests

struct EqPresetTests {
    @Test func rawValuesMatchProtocolBytes() {
        #expect(EqPreset.off.rawValue == 0x00)
        #expect(EqPreset.bright.rawValue == 0x10)
        #expect(EqPreset.excited.rawValue == 0x11)
        #expect(EqPreset.mellow.rawValue == 0x12)
        #expect(EqPreset.relaxed.rawValue == 0x13)
        #expect(EqPreset.vocal.rawValue == 0x14)
        #expect(EqPreset.treble.rawValue == 0x15)
        #expect(EqPreset.bass.rawValue == 0x16)
        #expect(EqPreset.speech.rawValue == 0x17)
        #expect(EqPreset.manual.rawValue == 0xA0)
    }

    @Test func everyPresetHasAName() {
        for preset in EqPreset.allCases {
            #expect(!preset.name.isEmpty)
        }
    }

    @Test func idIsRawValue() {
        #expect(EqPreset.bass.id == EqPreset.bass.rawValue)
    }
}

// MARK: - EqBandTests

struct EqBandTests {
    @Test func labelsMatchFrequencies() {
        #expect(EqBand.hz400.label == "400")
        #expect(EqBand.khz1.label == "1k")
        #expect(EqBand.khz2_5.label == "2.5k")
        #expect(EqBand.khz6_3.label == "6.3k")
        #expect(EqBand.khz16.label == "16k")
    }

    @Test func thereAreFiveBandsIndexedFromZero() {
        #expect(EqBand.allCases.count == 5)
        #expect(EqBand.allCases.map(\.rawValue) == [0, 1, 2, 3, 4])
    }
}

// MARK: - AutoPowerOffOptionTests

struct AutoPowerOffOptionTests {
    @Test func rawValuesMatchProtocolIndexes() {
        #expect(AutoPowerOffOption.off.rawValue == 0)
        #expect(AutoPowerOffOption.fiveMinutes.rawValue == 1)
        #expect(AutoPowerOffOption.thirtyMinutes.rawValue == 2)
        #expect(AutoPowerOffOption.oneHour.rawValue == 3)
        #expect(AutoPowerOffOption.threeHours.rawValue == 4)
        #expect(AutoPowerOffOption.whenTakenOff.rawValue == 5)
    }

    @Test func everyOptionHasALabel() {
        for option in AutoPowerOffOption.allCases {
            #expect(!option.label.isEmpty)
        }
    }
}
