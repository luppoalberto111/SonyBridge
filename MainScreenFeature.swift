import Bridge
import Client
import ComposableArchitecture
import Dependencies
import Foundation
import SwiftUI

// MARK: - MainScreenFeature

@Reducer struct MainScreenFeature {
    @ObservableState struct State: Equatable {
        var headphones = HeadphonesState()
        var showAbout = false
        var disconnected = DisconnectedReducer.State()
    }

    enum Action {
        case disconnected(DisconnectedReducer.Action)
        case disconnectButtonTapped
        case disconnectResponse(HeadphonesState)
        case refreshStatusRequested
        case snapshotReceived(HeadphonesState)
        case showAboutChanged(Bool)
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
    }

    enum CancelID { case dynamicPolling, watchConnection }

    @Dependency(\.headphonesClient)
    var client
    @Dependency(\.continuousClock)
    var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .disconnected(.delegate(.didConnect(snap))):
                    state.headphones = snap
                    return .merge(startPolling(), .send(.refreshStatusRequested))

                case .disconnected:
                    return .none

                case .disconnectButtonTapped:
                    state.headphones.connected = false
                    state.headphones.deviceName = ""
                    state.disconnected = DisconnectedReducer.State()
                    return .merge(
                        .cancel(id: CancelID.dynamicPolling),
                        .cancel(id: CancelID.watchConnection),
                        .run { send in
                            await send(.disconnectResponse(client.disconnect()))
                        }
                    )

                case let .disconnectResponse(snap):
                    state.headphones = snap
                    return .none

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
                        .cancel(id: CancelID.watchConnection)
                    )
            }
        }

        Scope(state: \.disconnected, action: \.disconnected) {
            DisconnectedReducer()
        }
    }

    /// Manual EQ (preset byte 0xA0 = 160). Called as the user drags a band or clear-bass slider.
    private func customEqEffect(bass: Int, bands: [Int]) -> Effect<Action> {
        .run { send in
            await send(.snapshotReceived(client.setCustomEq(bass: bass, bands: bands)))
        }
    }

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

// MARK: - MainScreenView

struct MainScreenView: View {
    let store: StoreOf<MainScreenFeature>

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if store.headphones.connected {
                ConnectedView(
                    state: store.headphones,
                    showAbout: Binding(
                        get: { store.showAbout },
                        set: { store.send(.showAboutChanged($0)) }
                    ),
                    disconnect: { store.send(.disconnectButtonTapped) },
                    setMode: { store.send(.setMode($0)) },
                    setLevel: { store.send(.setLevel($0)) },
                    setFocusOnVoice: { store.send(.setFocusOnVoice($0)) },
                    setEqualizer: { store.send(.setEqualizer($0)) },
                    setBand: { store.send(.setBand($0, $1)) },
                    setClearBass: { store.send(.setClearBass($0)) },
                    setDsee: { store.send(.setDsee($0)) },
                    setAdaptiveVolume: { store.send(.setAdaptiveVolume($0)) },
                    setSpeakToChat: { store.send(.setSpeakToChat($0)) },
                    setAutoPowerOff: { store.send(.setAutoPowerOff($0)) }
                )
            } else {
                DisconnectedView(
                    store: store.scope(state: \.disconnected, action: \.disconnected)
                )
            }
        }
        .frame(minWidth: 360, maxWidth: 560, minHeight: 500, maxHeight: 900)
    }
}
