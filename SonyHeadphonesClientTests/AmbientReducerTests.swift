import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct AmbientReducerTests {
    @Test func setModeUpdatesStateAndDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setMode(.noiseCanceling)) {
            $0.$headphones.withLock { $0.mode = .noiseCanceling }
        }
        await store.receive(\.delegate)
    }

    @Test func setLevelUpdatesStateAndDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setLevel(17)) {
            $0.$headphones.withLock { $0.ambientLevel = 17 }
        }
        await store.receive(\.delegate)
    }

    @Test func setFocusOnVoiceUpdatesStateAndDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setFocusOnVoice(true)) {
            $0.$headphones.withLock { $0.focusOnVoice = true }
        }
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
