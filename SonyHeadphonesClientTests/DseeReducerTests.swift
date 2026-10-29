import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct DseeReducerTests {
    @Test func setDseeUpdatesStateAndDelegates() async {
        let store = TestStore(initialState: DseeReducer.State(headphones: HeadphonesState())) {
            DseeReducer()
        }

        await store.send(.setDsee(true)) {
            $0.headphones.dsee = true
        }
        await store.receive(\.delegate)
    }

    @Test func initCopiesDseeFlagFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.dsee = true

        let state = DseeReducer.State(headphones: headphones)

        #expect(state.headphones.dsee)
    }
}
