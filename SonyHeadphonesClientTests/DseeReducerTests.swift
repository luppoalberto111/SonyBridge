import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct DseeReducerTests {
    private func state(_ uiState: HeadphonesUIState = .init()) -> DseeReducer.State {
        .init(uiState: Shared(value: uiState))
    }

    @Test func setDseeDelegates() async {
        let store = TestStore(
            initialState: state(),
            reducer: DseeReducer.init
        )

        await store.send(.setDsee(true))
        await store.receive(\.delegate)
    }

    @Test func initMapsDseeFlagFromSnapshot() {
        let state = DseeReducer.State(
            uiState: .init(value: HeadphonesUIState(SonyHeadphones(dsee: true)))
        )

        #expect(state.uiState.dsee)
    }
}
