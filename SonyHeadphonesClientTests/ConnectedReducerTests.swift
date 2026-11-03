import Bridge
import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct ConnectedReducerTests {
    private func connectedState() -> HeadphonesState {
        HeadphonesState(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true
        )
    }

    @Test func snapshotReceivedUpdatesEverySharedChildState() async {
        let snapshot = HeadphonesState(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            mode: .ambientSound,
            ambientLevel: 12,
            eqPreset: EqPreset.bass.rawValue,
            dsee: true,
            hasAdaptiveVolume: true,
            adaptiveVolume: true
        )

        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
        ) {
            ConnectedReducer()
        }

        await store.send(.snapshotReceived(snapshot)) {
            $0.$headphones.withLock { $0 = snapshot }
        }

        #expect(store.state.deviceHero.headphones == snapshot)
        #expect(store.state.ambient.headphones == snapshot)
        #expect(store.state.equalizer.headphones == snapshot)
        #expect(store.state.dsee.headphones == snapshot)
        #expect(store.state.settings.headphones == snapshot)
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
            }
            $0.uiState.errorMessage = nil
        }
        await store.receive(\.snapshotReceived)

        #expect(store.state.ambient.headphones.mode == .noiseCanceling)
        #expect(store.state.deviceHero.headphones.mode == .noiseCanceling)
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
            }
            $0.uiState.errorMessage = nil
        }
        await store.receive(\.snapshotReceived)

        #expect(store.state.equalizer.headphones.eqBands[0] == 5)
        #expect(store.state.equalizer.headphones.eqPreset == EqPreset.manual.rawValue)
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
            $0.$headphones.withLock { $0 = HeadphonesState() }
        }
        await store.receive(\.delegate)

        #expect(store.state.ambient.headphones.connected == false)
    }
}
