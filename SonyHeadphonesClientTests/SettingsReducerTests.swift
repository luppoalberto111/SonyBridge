import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct SettingsReducerTests {
    private func state(_ uiState: HeadphonesUIState = .init()) -> SettingsReducer.State {
        .init(uiState: Shared(value: uiState))
    }

    @Test func setAdaptiveVolumeDelegates() async {
        let store = TestStore(
            initialState: state(),
            reducer: SettingsReducer.init
        )

        await store.send(.setAdaptiveVolume(true))
        await store.receive(\.delegate)
    }

    @Test func setSpeakToChatDelegates() async {
        let store = TestStore(
            initialState: state(),
            reducer: SettingsReducer.init
        )

        await store.send(.setSpeakToChat(true))
        await store.receive(\.delegate)
    }

    @Test func setAutoPowerOffDelegates() async {
        let store = TestStore(initialState: state()) {
            SettingsReducer()
        }

        await store.send(.setAutoPowerOff(.thirtyMinutes))
        await store.receive(\.delegate)
    }

    @Test func initMapsCapabilitiesFromSnapshot() {
        let headphones = SonyHeadphones(
            hasAutoPowerOff: true,
            autoPowerOff: 99,
            hasSpeakToChat: true,
            speakToChat: true,
            hasAdaptiveVolume: true,
            adaptiveVolume: true
        )

        let state = SettingsReducer.State(
            uiState: Shared(value: HeadphonesUIState(headphones))
        )

        #expect(state.uiState.hasAdaptiveVolume)
        #expect(state.uiState.adaptiveVolume)
        #expect(state.uiState.hasSpeakToChat)
        #expect(state.uiState.speakToChat)
        #expect(state.uiState.hasAutoPowerOff)
        #expect(state.uiState.autoPowerOff == 99)
    }
}
