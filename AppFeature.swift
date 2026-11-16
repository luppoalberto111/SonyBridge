import ComposableArchitecture

// MARK: - AppFeature

/// Root of the app: the main window content.
@Reducer struct AppFeature {
    @ObservableState struct State: Equatable {
        var mainScreen: MainScreenFeature.State = .disconnected(.init())
        var launchAtLogin = LaunchAtLoginFeature.State()
    }

    enum Action {
        case mainScreen(MainScreenFeature.Action)
        case launchAtLogin(LaunchAtLoginFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.mainScreen, action: \.mainScreen, child: MainScreenFeature.init)
        Scope(state: \.launchAtLogin, action: \.launchAtLogin, child: LaunchAtLoginFeature.init)
        Reduce { _, action in
            switch action {
                case .launchAtLogin, .mainScreen:
                    return .none
            }
        }
    }
}
