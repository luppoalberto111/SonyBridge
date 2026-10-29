import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct EqualizerReducerTests {
    @Test func setEqualizerUpdatesPresetAndDelegates() async {
        let store = TestStore(initialState: EqualizerReducer.State(headphones: HeadphonesState())) {
            EqualizerReducer()
        }

        await store.send(.setEqualizer(EqPreset.excited.rawValue)) {
            $0.headphones.eqPreset = EqPreset.excited.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func setBandSwitchesToManualPreset() async {
        let store = TestStore(initialState: EqualizerReducer.State(headphones: HeadphonesState())) {
            EqualizerReducer()
        }

        await store.send(.setBand(2, 4)) {
            $0.headphones.eqBands[2] = 4
            $0.headphones.eqPreset = EqPreset.manual.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func setBandIgnoresOutOfRangeIndex() async {
        let store = TestStore(initialState: EqualizerReducer.State(headphones: HeadphonesState())) {
            EqualizerReducer()
        }

        await store.send(.setBand(9, 4))
    }

    @Test func setClearBassSwitchesToManualPreset() async {
        let store = TestStore(initialState: EqualizerReducer.State(headphones: HeadphonesState())) {
            EqualizerReducer()
        }

        await store.send(.setClearBass(6)) {
            $0.headphones.clearBass = 6
            $0.headphones.eqPreset = EqPreset.manual.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func initCopiesEqualizerFieldsFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.eqPreset = EqPreset.manual.rawValue
        headphones.eqBands = [1, -2, 3, 0, 5]
        headphones.clearBass = 7

        let state = EqualizerReducer.State(headphones: headphones)

        #expect(state.headphones.eqPreset == EqPreset.manual.rawValue)
        #expect(state.headphones.eqBands == [1, -2, 3, 0, 5])
        #expect(state.headphones.clearBass == 7)
    }
}
