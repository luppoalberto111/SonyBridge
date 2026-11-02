import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct SettingsReducerTests {
    @Test func setAdaptiveVolumeDelegates() async {
        let store = TestStore(
            initialState: SettingsReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            SettingsReducer()
        }

        await store.send(.setAdaptiveVolume(true))
        await store.receive(\.delegate)
    }

    @Test func setSpeakToChatDelegates() async {
        let store = TestStore(
            initialState: SettingsReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            SettingsReducer()
        }

        await store.send(.setSpeakToChat(true))
        await store.receive(\.delegate)
    }

    @Test func setAutoPowerOffDelegates() async {
        let store = TestStore(
            initialState: SettingsReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            SettingsReducer()
        }

        await store.send(.setAutoPowerOff(.thirtyMinutes))
        await store.receive(\.delegate)
    }

    @Test func initSharesCapabilitiesFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.hasAdaptiveVolume = true
        headphones.adaptiveVolume = true
        headphones.hasSpeakToChat = true
        headphones.speakToChat = true
        headphones.hasAutoPowerOff = true
        headphones.autoPowerOff = 99

        let state = SettingsReducer.State(headphones: Shared(value: headphones))

        #expect(state.headphones.hasAdaptiveVolume)
        #expect(state.headphones.adaptiveVolume)
        #expect(state.headphones.hasSpeakToChat)
        #expect(state.headphones.speakToChat)
        #expect(state.headphones.hasAutoPowerOff)
        #expect(state.headphones.autoPowerOff == 99)
    }
}
