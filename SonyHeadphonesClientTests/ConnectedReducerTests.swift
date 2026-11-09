import Bridge
import Client
import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@MainActor struct ConnectedReducerTests {
    private func connectedState() -> SonyHeadphones {
        SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true
        )
    }

    @Test func snapshotReceivedUpdatesEverySharedChildState() async {
        let snapshot = SonyHeadphones(
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

    @Test func setFocusOnVoiceWaitsForSnapshotInsteadOfUpdatingOptimistically() async {
        let client = HeadphonesTestClient(state: connectedState())
        await client.suspendWrites()
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.setFocusOnVoice(true)) {
            $0.uiState.focusOnVoiceLoading = true
            $0.uiState.errorMessage = nil
        }
        // The write is still in flight, so the toggle keeps its old value until the device confirms.
        #expect(store.state.headphones.focusOnVoice == false)
        #expect(store.state.ambient.headphones.focusOnVoice == false)
        #expect(store.state.uiState.focusOnVoiceLoading)

        await client.releaseWrites()
        let confirmed = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            focusOnVoice: true,
            supportsEqualizer: true
        )
        await store.receive(\.snapshotReceived) {
            $0.$headphones.withLock { $0 = confirmed }
            $0.uiState.focusOnVoiceLoading = false
        }

        #expect(store.state.headphones.focusOnVoice)
        #expect(store.state.ambient.headphones.focusOnVoice)
        #expect(store.state.uiState.focusOnVoiceLoading == false)
    }

    @Test func setAdaptiveVolumeWaitsForSnapshotInsteadOfUpdatingOptimistically() async {
        let state = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true,
            hasAdaptiveVolume: true
        )
        let client = HeadphonesTestClient(state: state)
        await client.suspendWrites()
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: state, showAbout: false)
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.setAdaptiveVolume(true)) {
            $0.uiState.adaptiveVolumeLoading = true
            $0.uiState.errorMessage = nil
        }
        // The write is still in flight, so the toggle keeps its old value until the device confirms.
        #expect(store.state.headphones.adaptiveVolume == false)
        #expect(store.state.settings.headphones.adaptiveVolume == false)
        #expect(store.state.uiState.adaptiveVolumeLoading)

        await client.releaseWrites()
        let confirmed = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true,
            hasAdaptiveVolume: true,
            adaptiveVolume: true
        )
        await store.receive(\.snapshotReceived) {
            $0.$headphones.withLock { $0 = confirmed }
            $0.uiState.adaptiveVolumeLoading = false
        }

        #expect(store.state.headphones.adaptiveVolume)
        #expect(store.state.settings.headphones.adaptiveVolume)
        #expect(store.state.uiState.adaptiveVolumeLoading == false)
    }

    @Test func setAutoPowerOffWaitsForSnapshotInsteadOfUpdatingOptimistically() async {
        let state = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true,
            hasAutoPowerOff: true
        )
        let client = HeadphonesTestClient(state: state)
        await client.suspendWrites()
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: state, showAbout: false)
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.setAutoPowerOff(.thirtyMinutes)) {
            $0.uiState.autoPowerOffLoading = true
            $0.uiState.errorMessage = nil
        }
        // The write is still in flight, so the picker keeps its old value until the device confirms.
        #expect(store.state.headphones.autoPowerOff == AutoPowerOffOption.off.rawValue)
        #expect(store.state.settings.headphones.autoPowerOff == AutoPowerOffOption.off.rawValue)
        #expect(store.state.uiState.autoPowerOffLoading)

        await client.releaseWrites()
        let confirmed = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true,
            hasAutoPowerOff: true,
            autoPowerOff: AutoPowerOffOption.thirtyMinutes.rawValue
        )
        await store.receive(\.snapshotReceived) {
            $0.$headphones.withLock { $0 = confirmed }
            $0.uiState.autoPowerOffLoading = false
        }

        #expect(store.state.headphones.autoPowerOff == AutoPowerOffOption.thirtyMinutes.rawValue)
        #expect(
            store.state.settings.headphones.autoPowerOff
                == AutoPowerOffOption.thirtyMinutes.rawValue
        )
        #expect(store.state.uiState.autoPowerOffLoading == false)
    }

    @Test func setDseeWaitsForSnapshotInsteadOfUpdatingOptimistically() async {
        let state = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true
        )
        let client = HeadphonesTestClient(state: state)
        await client.suspendWrites()
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: state, showAbout: false)
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.setDsee(true)) {
            $0.uiState.dseeLoading = true
            $0.uiState.errorMessage = nil
        }
        // The write is still in flight, so the toggle keeps its old value until the device confirms.
        #expect(store.state.headphones.dsee == false)
        #expect(store.state.dsee.headphones.dsee == false)
        #expect(store.state.uiState.dseeLoading)

        await client.releaseWrites()
        let confirmed = SonyHeadphones(
            connected: true,
            deviceModel: .left(.wh1000Xm5),
            supportsEqualizer: true,
            dsee: true
        )
        await store.receive(\.snapshotReceived) {
            $0.$headphones.withLock { $0 = confirmed }
            $0.uiState.dseeLoading = false
        }

        #expect(store.state.headphones.dsee)
        #expect(store.state.dsee.headphones.dsee)
        #expect(store.state.uiState.dseeLoading == false)
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
        let client = HeadphonesTestClient(state: SonyHeadphones())
        let store = TestStore(
            initialState: ConnectedReducer.State(headphones: connectedState(), showAbout: false)
        ) {
            ConnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.watchTick)
        await store.receive(\.watchTickResponse) {
            $0.$headphones.withLock { $0 = SonyHeadphones() }
        }
        await store.receive(\.delegate)

        #expect(store.state.ambient.headphones.connected == false)
    }
}
