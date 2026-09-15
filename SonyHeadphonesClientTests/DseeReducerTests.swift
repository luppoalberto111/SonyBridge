import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct DseeReducerTests {
    @Test func setDseeUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: DseeReducer.State()) {
            DseeReducer()
        }

        await store.send(.setDsee(true)) {
            $0.dsee = true
        }
        await store.receive(\.delegate)
    }

    @Test func syncCopiesDseeFlagFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.dsee = true

        var state = DseeReducer.State()
        state.sync(from: headphones)

        #expect(state.dsee)
    }
}
