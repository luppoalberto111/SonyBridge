import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct EqualizerReducerTests {
    @Test func setEqualizerUpdatesPresetAndDelegates() async {
        let store = TestStore(initialState: EqualizerReducer.State()) {
            EqualizerReducer()
        }

        await store.send(.setEqualizer(EqPreset.excited.rawValue)) {
            $0.eqPreset = EqPreset.excited.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func setBandSwitchesToManualPreset() async {
        let store = TestStore(initialState: EqualizerReducer.State()) {
            EqualizerReducer()
        }

        await store.send(.setBand(2, 4)) {
            $0.eqBands[2] = 4
            $0.eqPreset = EqPreset.manual.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func setBandIgnoresOutOfRangeIndex() async {
        let store = TestStore(initialState: EqualizerReducer.State()) {
            EqualizerReducer()
        }

        await store.send(.setBand(9, 4))
    }

    @Test func setClearBassSwitchesToManualPreset() async {
        let store = TestStore(initialState: EqualizerReducer.State()) {
            EqualizerReducer()
        }

        await store.send(.setClearBass(6)) {
            $0.clearBass = 6
            $0.eqPreset = EqPreset.manual.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func syncCopiesEqualizerFieldsFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.eqPreset = EqPreset.manual.rawValue
        headphones.eqBands = [1, -2, 3, 0, 5]
        headphones.clearBass = 7

        var state = EqualizerReducer.State()
        state.sync(from: headphones)

        #expect(state.eqPreset == EqPreset.manual.rawValue)
        #expect(state.eqBands == [1, -2, 3, 0, 5])
        #expect(state.clearBass == 7)
    }
}
