import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct MainScreenFeatureTests {
    @Test func didConnectSwapsToConnectedScreen() async {
        let snapshot = HeadphonesState(
            connected: true,
            deviceModel: .left(.wh1000Xm5)
        )

        let store = TestStore(
            initialState: MainScreenFeature.State.disconnected(DisconnectedReducer.State())
        ) {
            MainScreenFeature()
        }

        await store.send(.disconnected(.delegate(.didConnect(snapshot)))) {
            $0 = .connected(ConnectedReducer.State(headphones: snapshot, showAbout: false))
        }
    }

    @Test func didDisconnectSwapsBackToDisconnectedScreen() async {
        let snapshot = HeadphonesState(connected: true)

        let store = TestStore(
            initialState: MainScreenFeature.State.connected(
                ConnectedReducer.State(headphones: snapshot, showAbout: false)
            )
        ) {
            MainScreenFeature()
        }

        await store.send(.connected(.delegate(.didDisconnect))) {
            $0 = .disconnected(DisconnectedReducer.State())
        }
    }
}
