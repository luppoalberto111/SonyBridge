import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct AmbientReducerTests {
    @Test func setModeDelegates() async {
        let store = TestStore(
            initialState: AmbientReducer.State(
                headphones: Shared(value: SonyHeadphones()), uiState: .init(value: .init())
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
                headphones: Shared(value: SonyHeadphones()),
                uiState: .init(value: .init())
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
                headphones: Shared(value: SonyHeadphones()),
                uiState: .init(value: .init())
            )
        ) {
            AmbientReducer()
        }

        await store.send(.setFocusOnVoice(true))
        await store.receive(\.delegate)
    }

    @Test func initSharesEveryAmbientFieldFromHeadphones() {
        let headphones = SonyHeadphones(
            maxAmbientLevel: 18,
            mode: .ambientSound,
            ambientLevel: 14,
            focusOnVoice: true,
            focusOnVoiceAvailable: true
        )

        let state = AmbientReducer.State(
            headphones: Shared(value: headphones),
            uiState: .init(value: .init())
        )

        #expect(state.headphones.mode == .ambientSound)
        #expect(state.headphones.ambientLevel == 14)
        #expect(state.headphones.maxAmbientLevel == 18)
        #expect(state.headphones.focusOnVoice)
        #expect(state.headphones.focusOnVoiceAvailable)
    }
}
