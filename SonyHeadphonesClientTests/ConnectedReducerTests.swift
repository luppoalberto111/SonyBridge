import Bridge
import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct ConnectedReducerTests {
    private func connectedState() -> HeadphonesState {
        var state = HeadphonesState()
        state.connected = true
        state.deviceModel = .left(.wh1000Xm5)
        state.supportsEqualizer = true
        return state
    }

    @Test func snapshotReceivedFansOutToEveryChild() async {
        var snapshot = connectedState()
        snapshot.mode = .ambientSound
        snapshot.ambientLevel = 12
        snapshot.eqPreset = EqPreset.bass.rawValue
        snapshot.dsee = true
        snapshot.hasAdaptiveVolume = true
        snapshot.adaptiveVolume = true

        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
        ) {
            ConnectedReducer()
        }

        await store.send(.snapshotReceived(snapshot)) {
            let showAbout = $0.deviceHero.showAbout
            $0 = .init(headphones: snapshot, showAbout: showAbout)
        }
    }

    @Test func setModeForwardsToClientAndAppliesSnapshot() async {
        let client = HeadphonesTestClient(state: connectedState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
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
            let showAbout = $0.deviceHero.showAbout
            $0 = .init(headphones: $0.headphones, showAbout: showAbout)
        }
    }

    @Test func setBandIgnoresOutOfRangeIndex() async {
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
        ) {
            ConnectedReducer()
        }

        await store.send(.setBand(9, 3))
    }

    @Test func setBandSendsCustomEqualizerToClient() async {
        let client = HeadphonesTestClient(state: connectedState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
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
            let showAbout = $0.deviceHero.showAbout
            $0 = .init(headphones: $0.headphones, showAbout: showAbout)
        }
    }

    @Test func disconnectButtonTappedDelegatesDidDisconnect() async {
        let client = HeadphonesTestClient(state: connectedState())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
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
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.watchTick)
        await store.receive(\.watchTickResponse) {
            $0 = ConnectedReducer.State(headphones: HeadphonesState(), showAbout: false)
        }
        await store.receive(\.delegate)
    }
}
