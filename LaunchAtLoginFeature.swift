import ComposableArchitecture
import Dependencies

// MARK: - LaunchAtLoginFeature

/// Asks once whether the app may launch at login, then stays out of the way.
/// The answer is persisted so the prompt never appears again.
@Reducer struct LaunchAtLoginFeature {
    @ObservableState struct State: Equatable {
        var promptVisible = false
        var launchAtLoginEnabled = false
        @Shared(.appStorage("launchAtLoginPromptResolved"))
        var promptResolved = false
    }

    enum Action {
        case task
        case statusResponse(Bool)
        case allowTapped
        case denyTapped
        case setEnabledResponse(Bool)
    }

    @Dependency(\.launchAtLoginClient)
    var client

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case .task:
                    return .run { send in
                        await send(.statusResponse(client.isEnabled()))
                    }

                case let .statusResponse(enabled):
                    state.launchAtLoginEnabled = enabled
                    if !state.promptResolved {
                        state.promptVisible = true
                    }
                    return .none

                case .allowTapped:
                    state.promptVisible = false
                    state.promptResolved = true
                    return .run { send in
                        await send(.setEnabledResponse(client.setEnabled(true)))
                    }

                case .denyTapped:
                    state.promptVisible = false
                    state.promptResolved = true
                    return .none

                case let .setEnabledResponse(enabled):
                    state.launchAtLoginEnabled = enabled
                    return .none
            }
        }
    }
}
