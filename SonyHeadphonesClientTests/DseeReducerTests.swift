import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct DseeReducerTests {
    @Test func setDseeUpdatesStateAndDelegates() async {
        let store = TestStore(
            initialState: DseeReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            DseeReducer()
        }

        await store.send(.setDsee(true)) {
            $0.$headphones.withLock { $0.dsee = true }
        }
        await store.receive(\.delegate)
    }

    @Test func initSharesDseeFlagFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.dsee = true

        let state = DseeReducer.State(headphones: Shared(value: headphones))

        #expect(state.headphones.dsee)
    }
}
