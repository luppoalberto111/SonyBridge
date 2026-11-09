import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct EqualizerReducerTests {
    @Test func setEqualizerDelegates() async {
        let store = TestStore(
            initialState: EqualizerReducer.State(
                headphones: Shared(value: SonyHeadphones())
            )
        ) {
            EqualizerReducer()
        }

        await store.send(.setEqualizer(EqPreset.excited.rawValue))
        await store.receive(\.delegate)
    }

    @Test func setBandDelegates() async {
        let store = TestStore(
            initialState: EqualizerReducer.State(
                headphones: Shared(value: SonyHeadphones())
            )
        ) {
            EqualizerReducer()
        }

        await store.send(.setBand(2, 4))
        await store.receive(\.delegate)
    }

    @Test func setBandIgnoresOutOfRangeIndex() async {
        let store = TestStore(
            initialState: EqualizerReducer.State(
                headphones: Shared(value: SonyHeadphones())
            )
        ) {
            EqualizerReducer()
        }

        await store.send(.setBand(9, 4))
    }

    @Test func setClearBassDelegates() async {
        let store = TestStore(
            initialState: EqualizerReducer.State(
                headphones: Shared(value: SonyHeadphones())
            )
        ) {
            EqualizerReducer()
        }

        await store.send(.setClearBass(6))
        await store.receive(\.delegate)
    }

    @Test func initSharesEqualizerFieldsFromHeadphones() {
        var headphones = SonyHeadphones(eqPreset: EqPreset.manual.rawValue)
        headphones.eqBands = [1, -2, 3, 0, 5]
        headphones.clearBass = 7

        let state = EqualizerReducer.State(headphones: Shared(value: headphones))

        #expect(state.headphones.eqPreset == EqPreset.manual.rawValue)
        #expect(state.headphones.eqBands == [1, -2, 3, 0, 5])
        #expect(state.headphones.clearBass == 7)
    }
}
