import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct AmbientReducerTests {
    private func state(_ uiState: HeadphonesUIState = .init()) -> AmbientReducer.State {
        .init(uiState: Shared(value: uiState))
    }

    @Test func setModeDelegates() async {
        let store = TestStore(initialState: state()) {
            AmbientReducer()
        }

        await store.send(.setMode(.noiseCanceling))
        await store.receive(\.delegate)
    }

    @Test func setLevelDelegates() async {
        let store = TestStore(initialState: state()) {
            AmbientReducer()
        }

        await store.send(.setLevel(17))
        await store.receive(\.delegate)
    }

    @Test func setFocusOnVoiceDelegates() async {
        let store = TestStore(initialState: state()) {
            AmbientReducer()
        }

        await store.send(.setFocusOnVoice(true))
        await store.receive(\.delegate)
    }

    @Test func initMapsEveryAmbientFieldFromSnapshot() {
        let headphones = SonyHeadphones(
            maxAmbientLevel: 18,
            mode: .ambientSound,
            ambientLevel: 14,
            focusOnVoice: true,
            focusOnVoiceAvailable: true
        )

        let state = AmbientReducer.State(
            uiState: Shared(value: HeadphonesUIState(headphones))
        )

        #expect(state.uiState.mode == .ambientSound)
        #expect(state.uiState.ambientLevel == 14)
        #expect(state.uiState.maxAmbientLevel == 18)
        #expect(state.uiState.focusOnVoice)
        #expect(state.uiState.focusOnVoiceAvailable)
    }
}
