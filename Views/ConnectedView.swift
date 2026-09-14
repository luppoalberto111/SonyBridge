import Bridge
import Client
import ComposableArchitecture
import Dependencies
import SwiftUI

// MARK: - ConnectedReducer

/// Connected-screen feature: owns the connected headset state and all of
/// its effects (setters, polling, status refresh).
///
/// Exits back to the parent via `delegate` when the headset disconnects —
/// the parent then tears this feature down and shows the disconnected screen.
@Reducer struct ConnectedReducer {
    @ObservableState struct State: Equatable {
        var headphones: HeadphonesState
        var showAbout = false
    }

    enum Action {
        case task
        case refreshStatusRequested
        case snapshotReceived(HeadphonesState)
        case showAboutChanged(Bool)
        case disconnectButtonTapped
        case setMode(SHCAmbientMode)
        case setLevel(Int)
        case setFocusOnVoice(Bool)
        case setEqualizer(Int)
        case setBand(Int, Int)
        case setClearBass(Int)
        case setDsee(Bool)
        case setAutoPowerOff(AutoPowerOffOption)
        case setSpeakToChat(Bool)
        case setAdaptiveVolume(Bool)
        case dynamicTick
        case dynamicTickResponse(HeadphonesState)
        case watchTick
        case watchTickResponse(HeadphonesState)
        case delegate(Delegate)
    }

    enum Delegate {
        case didDisconnect
    }

    enum CancelID { case dynamicPolling, watchConnection }

    @Dependency(\.headphonesClient)
    var client
    @Dependency(\.continuousClock)
    var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case .task:
                    return .merge(startPolling(), .send(.refreshStatusRequested))

                case .refreshStatusRequested:
                    return .run { send in
                        await send(.snapshotReceived(client.refreshStatus()))
                        await send(.snapshotReceived(client.probeCapabilities()))
                    }

                case let .snapshotReceived(snap):
                    state.headphones = snap
                    return .none

                case let .showAboutChanged(show):
                    state.showAbout = show
                    return .none

                case .disconnectButtonTapped:
                    return .merge(
                        .cancel(id: CancelID.dynamicPolling),
                        .cancel(id: CancelID.watchConnection),
                        .run { send in
                            _ = await client.disconnect()
                            await send(.delegate(.didDisconnect))
                        }
                    )

                case let .setMode(mode):
                    state.headphones.mode = mode
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setMode(mode)))
                    }

                case let .setLevel(level):
                    state.headphones.ambientLevel = level
                    return .run { send in
                        await send(.snapshotReceived(client.setLevel(level)))
                    }

                case let .setFocusOnVoice(on):
                    state.headphones.focusOnVoice = on
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setFocusOnVoice(on)))
                    }

                case let .setEqualizer(preset):
                    state.headphones.eqPreset = preset
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setEqualizer(preset)))
                    }

                case let .setBand(index, value):
                    guard state.headphones.eqBands.indices.contains(index) else { return .none }
                    state.headphones.eqBands[index] = value
                    state.headphones.eqPreset = 0xA0
                    state.headphones.errorMessage = nil
                    return customEqEffect(
                        bass: state.headphones.clearBass,
                        bands: state.headphones.eqBands
                    )

                case let .setClearBass(value):
                    state.headphones.clearBass = value
                    state.headphones.eqPreset = 0xA0
                    state.headphones.errorMessage = nil
                    return customEqEffect(bass: value, bands: state.headphones.eqBands)

                case let .setDsee(on):
                    state.headphones.dsee = on
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setDsee(on)))
                    }

                case let .setAutoPowerOff(option):
                    state.headphones.autoPowerOff = option.rawValue
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setAutoPowerOff(option.rawValue)))
                    }

                case let .setSpeakToChat(on):
                    state.headphones.speakToChat = on
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setSpeakToChat(on)))
                    }

                case let .setAdaptiveVolume(on):
                    state.headphones.adaptiveVolume = on
                    state.headphones.errorMessage = nil
                    return .run { send in
                        await send(.snapshotReceived(client.setAdaptiveVolume(on)))
                    }

                case .dynamicTick:
                    return .run { send in
                        await send(.dynamicTickResponse(client.refreshDynamic()))
                    }

                case let .dynamicTickResponse(snap):
                    state.headphones = snap
                    return .none

                case .watchTick:
                    return .run { send in
                        await send(.watchTickResponse(client.pollConnection()))
                    }

                case let .watchTickResponse(snap):
                    state.headphones = snap
                    if snap.connected {
                        return .none
                    }
                    return .merge(
                        .cancel(id: CancelID.dynamicPolling),
                        .cancel(id: CancelID.watchConnection),
                        .send(.delegate(.didDisconnect))
                    )

                case .delegate:
                    return .none
            }
        }
    }

    /// Manual EQ (preset byte 0xA0 = 160). Called as the user drags a band or clear-bass slider.
    private func customEqEffect(bass: Int, bands: [Int]) -> Effect<Action> {
        .run { send in
            await send(.snapshotReceived(client.setCustomEq(bass: bass, bands: bands)))
        }
    }

    /// Polls the button-changeable state so the app stays in sync when you use
    /// the headphone's own controls, and watches the connection so a headset
    /// dropping RFCOMM on its own doesn't leave a stale "Connected".
    private func startPolling() -> Effect<Action> {
        .merge(
            .concatenate(
                .cancel(id: CancelID.dynamicPolling),
                .run { send in
                    while true {
                        try await clock.sleep(for: .seconds(2))
                        await send(.dynamicTick)
                    }
                }
                .cancellable(id: CancelID.dynamicPolling)
            ),
            .concatenate(
                .cancel(id: CancelID.watchConnection),
                .run { send in
                    while true {
                        try await clock.sleep(for: .seconds(1.5))
                        await send(.watchTick)
                    }
                }
                .cancellable(id: CancelID.watchConnection)
            )
        )
    }
}

// MARK: - ConnectedView

struct ConnectedView: View {
    let store: StoreOf<ConnectedReducer>

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                DeviceHeroView(
                    model: store.headphones.deviceHeroModel,
                    showAbout: Binding(
                        get: { store.showAbout },
                        set: { store.send(.showAboutChanged($0)) }
                    )
                ) { store.send(.disconnectButtonTapped) }
                AmbientView(
                    model: store.headphones.ambientModel,
                    setMode: { store.send(.setMode($0)) },
                    setLevel: { store.send(.setLevel($0)) },
                    setFocusOnVoice: { store.send(.setFocusOnVoice($0)) }
                )
                if store.headphones.supportsEqualizer {
                    EqualizerView(
                        model: store.headphones.equalizerModel,
                        setEqualizer: { store.send(.setEqualizer($0)) },
                        setBand: { store.send(.setBand($0, $1)) },
                        setClearBass: { store.send(.setClearBass($0)) }
                    )
                    DseeView(model: store.headphones.dseeModel) {
                        store.send(.setDsee($0))
                    }
                }
                if store.headphones.hasAdaptiveVolume || store.headphones.hasSpeakToChat
                    || store.headphones.hasAutoPowerOff {
                    SettingsView(
                        model: store.headphones.settingsModel,
                        setAdaptiveVolume: { store.send(.setAdaptiveVolume($0)) },
                        setSpeakToChat: { store.send(.setSpeakToChat($0)) },
                        setAutoPowerOff: { store.send(.setAutoPowerOff($0)) }
                    )
                }
                if let error = store.headphones.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.9))
                }
            }
            .padding(20)
        }
        .task { store.send(.task) }
    }
}

private func previewState() -> HeadphonesState {
    var state = HeadphonesState()
    state.connected = true
    state.deviceName = "WH-1000XM5"
    state.batteryLevel = 80
    state.codec = "LDAC"
    state.supportsEqualizer = true
    state.eqPreset = EqPreset.excited.rawValue
    state.hasAdaptiveVolume = true
    state.adaptiveVolume = true
    state.hasSpeakToChat = true
    state.hasAutoPowerOff = true
    state.autoPowerOff = AutoPowerOffOption.thirtyMinutes.rawValue
    return state
}

#Preview {
    ConnectedView(
        store: Store(initialState: ConnectedReducer.State(headphones: previewState())) {
            ConnectedReducer()
        }
    )
}

#Preview {
    ConnectedView(
        store: Store(initialState: ConnectedReducer.State(headphones: HeadphonesState())) {
            ConnectedReducer()
        }
    )
}
