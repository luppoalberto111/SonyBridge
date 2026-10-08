import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

// MARK: - MenuBarFeatureTests

@MainActor struct MenuBarFeatureTests {
    @Test func openTappedActivatesApp() async {
        var didActivate = false
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient.activateApp = {
                didActivate = true
            }
        }

        await store.send(.openTapped)
        #expect(didActivate)
    }

    @Test func quitTappedTerminatesApp() async {
        var didTerminate = false
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient.terminateApp = {
                didTerminate = true
            }
        }

        await store.send(.quitTapped)
        #expect(didTerminate)
    }

    @Test func connectTappedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.connectTapped)
        await store.receive(\.delegate)
    }

    @Test func disconnectTappedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.disconnectTapped)
        await store.receive(\.delegate)
    }
}

// MARK: - AppFeatureTests

@Suite(.serialized)
@MainActor struct AppFeatureTests {
    @Test func menuConnectForwardsAndSyncsConnectedState() async {
        var connectedSnapshot = HeadphonesState()
        connectedSnapshot.connected = true

        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient()
            $0.menuBarApplicationClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.menuBar(.delegate(.connectRequested)))
        await store.finish()

        #expect(store.state
            .mainScreen == .connected(ConnectedReducer.State(headphones: connectedSnapshot)))
        #expect(store.state.menuBar.isConnected == true)
    }

    @Test func menuDisconnectForwardsAndSyncsConnectedState() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"

        var menuState = MenuBarFeature.State()
        menuState.isConnected = true

        let store = TestStore(
            initialState: AppFeature.State(
                mainScreen: .connected(ConnectedReducer.State(headphones: snapshot)),
                menuBar: menuState
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient(state: snapshot)
            $0.menuBarApplicationClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.menuBar(.delegate(.disconnectRequested)))
        await store.finish()

        #expect(store.state.mainScreen == .disconnected(DisconnectedReducer.State()))
        #expect(store.state.menuBar.isConnected == false)
    }

    @Test func menuConnectIgnoredWhenAlreadyConnected() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true

        var menuState = MenuBarFeature.State()
        menuState.isConnected = true

        let store = TestStore(
            initialState: AppFeature.State(
                mainScreen: .connected(ConnectedReducer.State(headphones: snapshot)),
                menuBar: menuState
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.menuBar(.delegate(.connectRequested)))
    }

    @Test func menuDisconnectIgnoredWhenAlreadyDisconnected() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.menuBar(.delegate(.disconnectRequested)))
    }
}
