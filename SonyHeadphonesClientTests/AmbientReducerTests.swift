import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct AmbientReducerTests {
    @Test func setModeDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setMode(.noiseCanceling))
        await store.receive(\.delegate)
    }

    @Test func setLevelDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setLevel(17))
        await store.receive(\.delegate)
    }

    @Test func setFocusOnVoiceDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setFocusOnVoice(true))
        await store.receive(\.delegate)
    }

    @Test func initSharesEveryAmbientFieldFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.mode = .ambientSound
        headphones.ambientLevel = 14
        headphones.maxAmbientLevel = 18
        headphones.focusOnVoice = true
        headphones.focusOnVoiceAvailable = true

        let state = AmbientReducer.State(headphones: Shared(value: headphones))

        #expect(state.headphones.mode == .ambientSound)
        #expect(state.headphones.ambientLevel == 14)
        #expect(state.headphones.maxAmbientLevel == 18)
        #expect(state.headphones.focusOnVoice)
        #expect(state.headphones.focusOnVoiceAvailable)
    }
}
