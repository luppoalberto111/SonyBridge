import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct DeviceHeroReducerTests {
    @Test func showAboutChangedTogglesPopover() async {
        let store = TestStore(initialState: DeviceHeroReducer.State()) {
            DeviceHeroReducer()
        }

        await store.send(.showAboutChanged(true)) {
            $0.showAbout = true
        }
        await store.send(.showAboutChanged(false)) {
            $0.showAbout = false
        }
    }

    @Test func disconnectTappedDelegatesRequest() async {
        let store = TestStore(initialState: DeviceHeroReducer.State()) {
            DeviceHeroReducer()
        }

        await store.send(.disconnectTapped)
        await store.receive(\.delegate)
    }
}
