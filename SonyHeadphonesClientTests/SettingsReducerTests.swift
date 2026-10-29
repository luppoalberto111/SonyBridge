import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct SettingsReducerTests {
    @Test func setAdaptiveVolumeUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: SettingsReducer.State(headphones: HeadphonesState())) {
            SettingsReducer()
        }

        await store.send(.setAdaptiveVolume(true)) {
            $0.headphones.adaptiveVolume = true
        }
        await store.receive(\.delegate)
    }

    @Test func setSpeakToChatUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: SettingsReducer.State(headphones: HeadphonesState())) {
            SettingsReducer()
        }

        await store.send(.setSpeakToChat(true)) {
            $0.headphones.speakToChat = true
        }
        await store.receive(\.delegate)
    }

    @Test func setAutoPowerOffUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: SettingsReducer.State(headphones: HeadphonesState())) {
            SettingsReducer()
        }

        await store.send(.setAutoPowerOff(.thirtyMinutes)) {
            $0.headphones.autoPowerOff = AutoPowerOffOption.thirtyMinutes.rawValue
        }
        await store.receive(\.delegate)
    }

    @Test func initCopiesCapabilitiesFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.hasAdaptiveVolume = true
        headphones.adaptiveVolume = true
        headphones.hasSpeakToChat = true
        headphones.speakToChat = true
        headphones.hasAutoPowerOff = true
        headphones.autoPowerOff = 99

        let state = SettingsReducer.State(headphones: headphones)

        #expect(state.headphones.hasAdaptiveVolume)
        #expect(state.headphones.adaptiveVolume)
        #expect(state.headphones.hasSpeakToChat)
        #expect(state.headphones.speakToChat)
        #expect(state.headphones.hasAutoPowerOff)
        #expect(state.headphones.autoPowerOff == 99)
    }
}
