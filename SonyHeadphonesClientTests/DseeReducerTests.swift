import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct DseeReducerTests {
    @Test func setDseeDelegates() async {
        let store = TestStore(
            initialState: DseeReducer.State(
                headphones: Shared(value: HeadphonesState()), uiState: .init(value: .init())
            ),
            reducer: DseeReducer.init
        )

        await store.send(.setDsee(true))
        await store.receive(\.delegate)
    }

    @Test func initSharesDseeFlagFromHeadphones() {
        let state = DseeReducer.State(
            headphones: .init(value: .init(dsee: true)),
            uiState: .init(value: .init())
        )

        #expect(state.headphones.dsee)
    }
}
