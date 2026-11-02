import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct DseeReducerTests {
    @Test func setDseeDelegates() async {
        let store = TestStore(
            initialState: DseeReducer.State(
                headphones: Shared(value: HeadphonesState())
            )
        ) {
            DseeReducer()
        }

        await store.send(.setDsee(true))
        await store.receive(\.delegate)
    }

    @Test func initSharesDseeFlagFromHeadphones() {
        var headphones = HeadphonesState()
        headphones.dsee = true

        let state = DseeReducer.State(headphones: Shared(value: headphones))

        #expect(state.headphones.dsee)
    }
}
