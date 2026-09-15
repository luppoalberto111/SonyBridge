import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct AmbientReducerTests {
    @Test func setModeUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: AmbientReducer.State()) {
            AmbientReducer()
        }

        await store.send(.setMode(.noiseCanceling)) {
            $0.mode = .noiseCanceling
        }
        await store.receive(\.delegate)
    }

    @Test func setLevelUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: AmbientReducer.State()) {
            AmbientReducer()
        }

        await store.send(.setLevel(17)) {
            $0.ambientLevel = 17
        }
        await store.receive(\.delegate)
    }

    @Test func setFocusOnVoiceUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: AmbientReducer.State()) {
            AmbientReducer()
        }

        await store.send(.setFocusOnVoice(true)) {
            $0.focusOnVoice = true
        }
        await store.receive(\.delegate)
    }

    @Test func syncCopiesEveryAmbientFieldFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.mode = .ambientSound
        headphones.ambientLevel = 14
        headphones.maxAmbientLevel = 18
        headphones.focusOnVoice = true
        headphones.focusOnVoiceAvailable = true

        var state = AmbientReducer.State()
        state.sync(from: headphones)

        #expect(state.mode == .ambientSound)
        #expect(state.ambientLevel == 14)
        #expect(state.maxAmbientLevel == 18)
        #expect(state.focusOnVoice)
        #expect(state.focusOnVoiceAvailable)
    }
}
