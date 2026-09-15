import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct SettingsReducerTests {
    @Test func setAdaptiveVolumeUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: SettingsReducer.State()) {
            SettingsReducer()
        }

        await store.send(.setAdaptiveVolume(true)) {
            $0.adaptiveVolume = true
        }
        await store.receive(\.delegate)
    }

    @Test func setSpeakToChatUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: SettingsReducer.State()) {
            SettingsReducer()
        }

        await store.send(.setSpeakToChat(true)) {
            $0.speakToChat = true
        }
        await store.receive(\.delegate)
    }

    @Test func setAutoPowerOffUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: SettingsReducer.State()) {
            SettingsReducer()
        }

        await store.send(.setAutoPowerOff(.thirtyMinutes)) {
            $0.autoPowerOff = .thirtyMinutes
        }
        await store.receive(\.delegate)
    }

    @Test func syncCopiesCapabilitiesAndFallsBackToOffForUnknownRawValue() {
        var headphones = HeadphonesState()
        headphones.hasAdaptiveVolume = true
        headphones.adaptiveVolume = true
        headphones.hasSpeakToChat = true
        headphones.speakToChat = true
        headphones.hasAutoPowerOff = true
        headphones.autoPowerOff = 99

        var state = SettingsReducer.State()
        state.sync(from: headphones)

        #expect(state.hasAdaptiveVolume)
        #expect(state.adaptiveVolume)
        #expect(state.hasSpeakToChat)
        #expect(state.speakToChat)
        #expect(state.hasAutoPowerOff)
        #expect(state.autoPowerOff == .off)
    }
}
