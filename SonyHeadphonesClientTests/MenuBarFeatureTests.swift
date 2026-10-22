import Bridge
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

    @Test func batteryMenuTitleFormatsKnownAndUnknownLevels() {
        #expect(batteryMenuTitle(level: 80) == "Battery: 80%")
        #expect(batteryMenuTitle(level: 0) == "Battery: 0%")
        #expect(batteryMenuTitle(level: -1) == "Battery: --")
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

    @Test func ambientModeTappedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.ambientModeTapped(.noiseCanceling))
        await store.receive(\.delegate)
    }

    @Test func ambientLevelPickedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.ambientLevelPicked(15))
        await store.receive(\.delegate)
    }

    @Test func focusOnVoicePickedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.focusOnVoicePicked(true))
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
        await store.skipReceivedActions()

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
        await store.skipReceivedActions()

        #expect(store.state.mainScreen == .disconnected(DisconnectedReducer.State()))
        #expect(store.state.menuBar.isConnected == false)
    }

    @Test func menuAmbientModeForwardsAndSyncsSharedMode() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"
        snapshot.mode = .off

        let store = TestStore(
            initialState: AppFeature.State(
                mainScreen: .connected(ConnectedReducer.State(headphones: snapshot))
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient(state: snapshot)
            $0.menuBarApplicationClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.menuBar(.delegate(.ambientModeSelected(.noiseCanceling))))
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.menuBar.ambientMode == .noiseCanceling)
        guard case let .connected(connectedState) = store.state.mainScreen else {
            Issue.record("Expected connected screen after ambient mode selection")
            return
        }
        #expect(connectedState.headphones.mode == .noiseCanceling)
    }

    @Test func menuAmbientLevelForwardsAndSyncsSharedLevel() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"
        snapshot.mode = .ambientSound
        snapshot.ambientLevel = 10

        let store = TestStore(
            initialState: AppFeature.State(
                mainScreen: .connected(ConnectedReducer.State(headphones: snapshot))
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient(state: snapshot)
            $0.menuBarApplicationClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.menuBar(.delegate(.ambientLevelSelected(15))))
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.menuBar.ambientLevel == 15)
        guard case let .connected(connectedState) = store.state.mainScreen else {
            Issue.record("Expected connected screen after ambient level selection")
            return
        }
        #expect(connectedState.headphones.ambientLevel == 15)
    }

    @Test func menuFocusOnVoiceForwardsAndSyncsSharedValue() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"
        snapshot.mode = .ambientSound
        snapshot.focusOnVoice = false

        let store = TestStore(
            initialState: AppFeature.State(
                mainScreen: .connected(ConnectedReducer.State(headphones: snapshot))
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient(state: snapshot)
            $0.menuBarApplicationClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.menuBar(.delegate(.focusOnVoiceSelected(true))))
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.menuBar.focusOnVoice == true)
        guard case let .connected(connectedState) = store.state.mainScreen else {
            Issue.record("Expected connected screen after focus-on-voice selection")
            return
        }
        #expect(connectedState.headphones.focusOnVoice == true)
    }

    @Test func menuAmbientModeIgnoredWhenDisconnected() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.menuBar(.delegate(.ambientModeSelected(.noiseCanceling))))
    }

    @Test func menuAmbientControlsIgnoredWhenDisconnected() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.menuBar(.delegate(.ambientLevelSelected(15))))
        await store.send(.menuBar(.delegate(.focusOnVoiceSelected(true))))
    }

    @Test func didConnectSyncsSharedAmbientMode() async {
        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"
        snapshot.mode = .ambientSound
        snapshot.ambientLevel = 14
        snapshot.focusOnVoice = true
        snapshot.batteryLevel = 80

        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient(state: snapshot)
            $0.menuBarApplicationClient = .testValue
        }
        store.exhaustivity = .off

        await store.send(.mainScreen(.disconnected(.delegate(.didConnect(snapshot)))))
        await store.finish()

        #expect(store.state.menuBar.ambientMode == .ambientSound)
        #expect(store.state.menuBar.ambientLevel == 14)
        #expect(store.state.menuBar.focusOnVoice == true)
        #expect(store.state.menuBar.batteryLevel == 80)
    }

    @Test func unknownBatterySnapshotKeepsKnownSharedValue() async {
        var menuState = MenuBarFeature.State()
        menuState.batteryLevel = 80

        var snapshot = HeadphonesState()
        snapshot.connected = true
        snapshot.deviceName = "WH-1000XM5"

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

        await store.send(.mainScreen(.connected(.snapshotReceived(snapshot))))
        await store.finish()

        #expect(store.state.menuBar.batteryLevel == 80)
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
