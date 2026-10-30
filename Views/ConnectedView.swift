import Bridge
import Client
import ComposableArchitecture
import Dependencies
import SwiftUI

// MARK: - ConnectedReducer

@Reducer struct ConnectedReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var headphones: HeadphonesState
        var deviceHero: DeviceHeroReducer.State
        var ambient: AmbientReducer.State
        var equalizer: EqualizerReducer.State
        var dsee: DseeReducer.State
        var settings: SettingsReducer.State

        init(
            headphones: HeadphonesState,
            showAbout: Bool
        ) {
            let shared = Shared(value: headphones)
            self._headphones = shared
            self.deviceHero = .init(headphones: shared, showAbout: showAbout)
            self.ambient = .init(headphones: shared)
            self.equalizer = .init(headphones: shared)
            self.dsee = .init(headphones: shared)
            self.settings = .init(headphones: shared)
        }
    }

    enum Action {
        case deviceHero(DeviceHeroReducer.Action)
        case ambient(AmbientReducer.Action)
        case equalizer(EqualizerReducer.Action)
        case dsee(DseeReducer.Action)
        case settings(SettingsReducer.Action)
        case task
        case refreshStatusRequested
        case snapshotReceived(HeadphonesState)
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
                case .deviceHero(.delegate(.disconnectRequested)):
                    return disconnectEffect()

                case .deviceHero:
                    return .none

                case let .ambient(.delegate(.setMode(mode))):
                    return .send(.setMode(mode))

                case let .ambient(.delegate(.setLevel(level))):
                    return .send(.setLevel(level))

                case let .ambient(.delegate(.setFocusOnVoice(on))):
                    return .send(.setFocusOnVoice(on))

                case .ambient:
                    return .none

                case let .equalizer(.delegate(.setEqualizer(preset))):
                    return .send(.setEqualizer(preset))

                case let .equalizer(.delegate(.setBand(index, value))):
                    return .send(.setBand(index, value))

                case let .equalizer(.delegate(.setClearBass(value))):
                    return .send(.setClearBass(value))

                case .equalizer:
                    return .none

                case let .dsee(.delegate(.setDsee(on))):
                    return .send(.setDsee(on))

                case .dsee:
                    return .none

                case let .settings(.delegate(.setAdaptiveVolume(on))):
                    return .send(.setAdaptiveVolume(on))

                case let .settings(.delegate(.setSpeakToChat(on))):
                    return .send(.setSpeakToChat(on))

                case let .settings(.delegate(.setAutoPowerOff(option))):
                    return .send(.setAutoPowerOff(option))

                case .settings:
                    return .none

                case .task:
                    return .merge(startPolling(), .send(.refreshStatusRequested))

                case .refreshStatusRequested:
                    return .run { send in
                        await send(.snapshotReceived(client.refreshStatus()))
                        await send(.snapshotReceived(client.probeCapabilities()))
                    }

                case let .snapshotReceived(snap):
                    state.$headphones.withLock { $0 = snap }
                    return .none

                case .disconnectButtonTapped:
                    return disconnectEffect()

                case let .setMode(mode):
                    state.$headphones.withLock {
                        $0.mode = mode
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setMode(mode)))
                    }

                case let .setLevel(level):
                    state.$headphones.withLock { $0.ambientLevel = level }
                    return .run { send in
                        await send(.snapshotReceived(client.setLevel(level)))
                    }

                case let .setFocusOnVoice(on):
                    state.$headphones.withLock {
                        $0.focusOnVoice = on
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setFocusOnVoice(on)))
                    }

                case let .setEqualizer(preset):
                    state.$headphones.withLock {
                        $0.eqPreset = preset
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setEqualizer(preset)))
                    }

                case let .setBand(index, value):
                    guard state.headphones.eqBands.indices.contains(index) else { return .none }
                    let (bass, bands) = state.$headphones.withLock { headphones -> (Int, [Int]) in
                        headphones.eqBands[index] = value
                        headphones.eqPreset = 0xA0
                        headphones.errorMessage = nil
                        return (headphones.clearBass, headphones.eqBands)
                    }
                    return customEqEffect(bass: bass, bands: bands)

                case let .setClearBass(value):
                    let bands = state.$headphones.withLock { headphones -> [Int] in
                        headphones.clearBass = value
                        headphones.eqPreset = 0xA0
                        headphones.errorMessage = nil
                        return headphones.eqBands
                    }
                    return customEqEffect(bass: value, bands: bands)

                case let .setDsee(on):
                    state.$headphones.withLock {
                        $0.dsee = on
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setDsee(on)))
                    }

                case let .setAutoPowerOff(option):
                    state.$headphones.withLock {
                        $0.autoPowerOff = option.rawValue
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setAutoPowerOff(option.rawValue)))
                    }

                case let .setSpeakToChat(on):
                    state.$headphones.withLock {
                        $0.speakToChat = on
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setSpeakToChat(on)))
                    }

                case let .setAdaptiveVolume(on):
                    state.$headphones.withLock {
                        $0.adaptiveVolume = on
                        $0.errorMessage = nil
                    }
                    return .run { send in
                        await send(.snapshotReceived(client.setAdaptiveVolume(on)))
                    }

                case .dynamicTick:
                    return .run { send in
                        await send(.dynamicTickResponse(client.refreshDynamic()))
                    }

                case let .dynamicTickResponse(snap):
                    state.$headphones.withLock { $0 = snap }
                    return .none

                case .watchTick:
                    return .run { send in
                        await send(.watchTickResponse(client.pollConnection()))
                    }

                case let .watchTickResponse(snap):
                    state.$headphones.withLock { $0 = snap }
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

        Scope(state: \.deviceHero, action: \.deviceHero) {
            DeviceHeroReducer()
        }
        Scope(state: \.ambient, action: \.ambient) {
            AmbientReducer()
        }
        Scope(state: \.equalizer, action: \.equalizer) {
            EqualizerReducer()
        }
        Scope(state: \.dsee, action: \.dsee) {
            DseeReducer()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsReducer()
        }
    }

    private func disconnectEffect() -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.dynamicPolling),
            .cancel(id: CancelID.watchConnection),
            .run { send in
                _ = await client.disconnect()
                await send(.delegate(.didDisconnect))
            }
        )
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
                    store: store.scope(state: \.deviceHero, action: \.deviceHero)
                )
                AmbientView(
                    store: store.scope(state: \.ambient, action: \.ambient)
                )
                if store.headphones.supportsEqualizer {
                    EqualizerView(
                        store: store.scope(state: \.equalizer, action: \.equalizer)
                    )
                    DseeView(
                        store: store.scope(state: \.dsee, action: \.dsee)
                    )
                }
                if store.headphones.hasAdaptiveVolume || store.headphones.hasSpeakToChat
                    || store.headphones.hasAutoPowerOff {
                    SettingsView(
                        store: store.scope(state: \.settings, action: \.settings)
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
    state.deviceModel = .left(.wh1000Xm5)
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
        store: Store(
            initialState: .init(headphones: previewState(), showAbout: false),
            reducer: ConnectedReducer.init
        )
    )
}

#Preview {
    ConnectedView(
        store: Store(
            initialState: .init(headphones: .init(), showAbout: false),
            reducer: ConnectedReducer.init
        )
    )
}
