import Bridge
import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct ConnectedReducerTests {
    private func connectedState() -> HeadphonesState {
        var state = HeadphonesState()
        state.connected = true
        state.deviceName = "WH-1000XM5"
        state.supportsEqualizer = true
        return state
    }

    @Test func snapshotReceivedFansOutToEveryChild() async {
        var snapshot = connectedState()
        snapshot.mode = .ambientSound
        snapshot.ambientLevel = 12
        snapshot.eqPreset = EqPreset.bass.rawValue
        snapshot.hasAdaptiveVolume = true
        snapshot.adaptiveVolume = true

        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState())
        ) {
            ConnectedReducer()
        }

        await store.send(.snapshotReceived(snapshot)) {
            $0.headphones = snapshot
            $0.deviceHero.headphones = snapshot
            $0.ambient.mode = .ambientSound
            $0.ambient.ambientLevel = 12
            $0.equalizer.eqPreset = EqPreset.bass.rawValue
            $0.settings.hasAdaptiveVolume = true
            $0.settings.adaptiveVolume = true
        }
    }

    @Test func setModeForwardsToClientAndAppliesSnapshot() async {
        let client = HeadphonesTestClient(state: connectedState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState())
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.setMode(.noiseCanceling)) {
            $0.headphones.mode = .noiseCanceling
            $0.headphones.errorMessage = nil
        }
        await store.receive(\.snapshotReceived) {
            $0.headphones.mode = .noiseCanceling
            $0.ambient.mode = .noiseCanceling
        }
    }

    @Test func setBandIgnoresOutOfRangeIndex() async {
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState())
        ) {
            ConnectedReducer()
        }

        await store.send(.setBand(9, 3))
    }

    @Test func setBandSendsCustomEqualizerToClient() async {
        let client = HeadphonesTestClient(state: connectedState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState())
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.setBand(0, 5)) {
            $0.headphones.eqBands[0] = 5
            $0.headphones.eqPreset = EqPreset.manual.rawValue
            $0.headphones.errorMessage = nil
        }
        await store.receive(\.snapshotReceived) {
            $0.headphones.eqBands[0] = 5
            $0.headphones.eqPreset = EqPreset.manual.rawValue
            $0.equalizer.eqBands[0] = 5
            $0.equalizer.eqPreset = EqPreset.manual.rawValue
        }
    }

    @Test func disconnectButtonTappedDelegatesDidDisconnect() async {
        let client = HeadphonesTestClient(state: connectedState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState())
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.disconnectButtonTapped)
        await store.receive(\.delegate)
    }

    @Test func watchTickReportsDisconnectWhenHeadphonesDropOff() async {
        let client = HeadphonesTestClient(state: HeadphonesState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState())
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.dynamicTick)
        await store.receive(\.dynamicTickResponse) {
            $0.headphones = HeadphonesState()
            $0.deviceHero.headphones = HeadphonesState()
            $0.ambient = AmbientReducer.State()
            $0.equalizer = EqualizerReducer.State()
            $0.settings = SettingsReducer.State()
        }
        await store.receive(\.delegate)
    }
}
