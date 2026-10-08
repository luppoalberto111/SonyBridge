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
        @Shared(.isConnected)
        var isConnected: Bool
    }

    enum Action {
        case mainScreen(MainScreenFeature.Action)
        case menuBar(MenuBarFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.mainScreen, action: \.mainScreen) {
            MainScreenFeature()
        }
        Scope(state: \.menuBar, action: \.menuBar) {
            MenuBarFeature()
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

                case .mainScreen(.disconnected(.delegate(.didConnect))):
                    state.isConnected = true
                    return .none

                case .mainScreen(.connected(.delegate(.didDisconnect))):
                    state.isConnected = false
                    return .none

                case .mainScreen, .menuBar:
                    return .none
            }
        }
    }
}
