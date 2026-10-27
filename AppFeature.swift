import Bridge
import Client
import ComposableArchitecture

// MARK: - AppFeature

/// Root of the app: the main window content plus the menu-bar status item.
///
/// `MenuBarFeature` delegate actions are forwarded to `MainScreenFeature`,
/// and connection transitions sync back so the menu title stays accurate.
@Reducer struct AppFeature {
    @ObservableState struct State: Equatable {
        var mainScreen: MainScreenFeature.State = .disconnected(.init())
        var menuBar = MenuBarFeature.State()
        var launchAtLogin = LaunchAtLoginFeature.State()
        @Shared(.isConnected)
        var isConnected: Bool
        @Shared(.ambientMode)
        var ambientMode: SHCAmbientMode
        @Shared(.ambientLevel)
        var ambientLevel: Int
        @Shared(.maxAmbientLevel)
        var maxAmbientLevel: Int
        @Shared(.focusOnVoice)
        var focusOnVoice: Bool
        @Shared(.batteryLevel)
        var batteryLevel: Int
    }

    enum Action {
        case mainScreen(MainScreenFeature.Action)
        case menuBar(MenuBarFeature.Action)
        case launchAtLogin(LaunchAtLoginFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.mainScreen, action: \.mainScreen) {
            MainScreenFeature()
        }
        Scope(state: \.menuBar, action: \.menuBar) {
            MenuBarFeature()
        }
        Scope(state: \.launchAtLogin, action: \.launchAtLogin) {
            LaunchAtLoginFeature()
        }
        Reduce { state, action in
            switch action {
                case .menuBar(.delegate(.connectRequested)):
                    guard case .disconnected = state.mainScreen else {
                        return .none
                    }
                    return .send(.mainScreen(.disconnected(.connectButtonTapped)))

                case .menuBar(.delegate(.disconnectRequested)):
                    guard case .connected = state.mainScreen else {
                        return .none
                    }
                    return .send(.mainScreen(.connected(.disconnectButtonTapped)))

                case let .menuBar(.delegate(.ambientModeSelected(mode))):
                    guard case .connected = state.mainScreen else {
                        return .none
                    }
                    return .send(.mainScreen(.connected(.setMode(mode))))

                case let .menuBar(.delegate(.ambientLevelSelected(level))):
                    guard case .connected = state.mainScreen else {
                        return .none
                    }
                    return .send(.mainScreen(.connected(.setLevel(level))))

                case let .menuBar(.delegate(.focusOnVoiceSelected(focusOn))):
                    guard case .connected = state.mainScreen else {
                        return .none
                    }
                    return .send(.mainScreen(.connected(.setFocusOnVoice(focusOn))))

                case let .mainScreen(.disconnected(.delegate(.didConnect(snapshot)))):
                    state.$isConnected.withLock { $0 = true }
                    state.syncSharedHeadphoneState(from: snapshot)
                    return .none

                case .mainScreen(.connected(.delegate(.didDisconnect))):
                    state.$isConnected.withLock { $0 = false }
                    return .none

                case let .mainScreen(.connected(.snapshotReceived(snapshot))):
                    state.syncSharedHeadphoneState(from: snapshot)
                    return .none

                case let .mainScreen(.connected(.dynamicTickResponse(snapshot))):
                    state.syncSharedHeadphoneState(from: snapshot)
                    return .none

                case let .mainScreen(.connected(.watchTickResponse(snapshot))):
                    state.syncSharedHeadphoneState(from: snapshot)
                    return .none

                case .launchAtLogin, .mainScreen, .menuBar:
                    return .none
            }
        }
    }
}

extension AppFeature.State {
    /// Mirrors the headphone-driven values into shared state
    /// so the menu bar stays in sync with the app and the headphones.
    mutating func syncSharedHeadphoneState(from snapshot: HeadphonesState) {
        $ambientMode.withLock { $0 = snapshot.mode }
        $ambientLevel.withLock { $0 = snapshot.ambientLevel }
        $maxAmbientLevel.withLock { $0 = snapshot.maxAmbientLevel }
        $focusOnVoice.withLock { $0 = snapshot.focusOnVoice }
        // Snapshots can carry unknown (-1) while the inquiry is still pending;
        // never let that wipe a known menu value back to "--".
        if snapshot.batteryLevel >= 0 {
            $batteryLevel.withLock { $0 = snapshot.batteryLevel }
        }
    }
}
