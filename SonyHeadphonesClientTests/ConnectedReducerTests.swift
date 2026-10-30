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
            $0.sync(from: snapshot)
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
            $0.$headphones.withLock {
                $0.mode = .noiseCanceling
                $0.errorMessage = nil
            }
        }
        await store.receive(\.snapshotReceived) {
            $0.sync(from: $0.headphones)
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
            $0.$headphones.withLock {
                $0.eqBands[0] = 5
                $0.eqPreset = EqPreset.manual.rawValue
                $0.errorMessage = nil
            }
        }
        await store.receive(\.snapshotReceived) {
            $0.sync(from: $0.headphones)
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
            $0.sync(from: HeadphonesState())
        }
        await store.receive(\.delegate)
    }
}
