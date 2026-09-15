import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct MainScreenFeatureTests {
    @Test func didConnectSwapsToConnectedScreen() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"

        let store = TestStore(
            initialState: MainScreenFeature.State.disconnected(DisconnectedReducer.State())
        ) {
            MainScreenFeature()
        }

        await store.send(.disconnected(.delegate(.didConnect(snapshot)))) {
            $0 = .connected(ConnectedReducer.State(headphones: snapshot))
        }
    }

    @Test func didDisconnectSwapsBackToDisconnectedScreen() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true

        let store = TestStore(
            initialState: MainScreenFeature.State.connected(
                ConnectedReducer.State(headphones: snapshot)
            )
        ) {
            MainScreenFeature()
        }

        await store.send(.connected(.delegate(.didDisconnect))) {
            $0 = .disconnected(DisconnectedReducer.State())
        }
    }
}
