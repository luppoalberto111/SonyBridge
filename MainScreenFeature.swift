import ComposableArchitecture
import SwiftUI

// MARK: - MainScreenFeature

/// Root switchboard: exactly one of the two screens is active.
///
/// All behavior lives in the children; this reducer only swaps between them
/// on connect / disconnect delegates.
@Reducer struct MainScreenFeature {
    @ObservableState
    @CasePathable
    @dynamicMemberLookup enum State: Equatable {
        case disconnected(DisconnectedReducer.State)
        case connected(ConnectedReducer.State)
    }

    @CasePathable enum Action {
        case disconnected(DisconnectedReducer.Action)
        case connected(ConnectedReducer.Action)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .disconnected(.delegate(.didConnect(snap))):
                    state = .connected(ConnectedReducer.State(headphones: snap))
                    return .none

                case .connected(.delegate(.didDisconnect)):
                    state = .disconnected(DisconnectedReducer.State())
                    return .none

                case .connected, .disconnected:
                    return .none
            }
        }
        .ifCaseLet(\.disconnected, action: \.disconnected) {
            DisconnectedReducer()
        }
        .ifCaseLet(\.connected, action: \.connected) {
            ConnectedReducer()
        }
    }
}

// MARK: - MainScreenView

struct MainScreenView: View {
    let store: StoreOf<MainScreenFeature>

    var body: some View {
        ZStack {
            Color(.bg).ignoresSafeArea()
            switch store.state {
                case .disconnected:
                    if let store = store.scope(\.disconnected, action: \.disconnected) {
                        DisconnectedView(store: store)
                    }
                case .connected:
                    if let store = store.scope(\.connected, action: \.connected) {
                        ConnectedView(store: store)
                    }
            }
        }
        .frame(minWidth: 360, maxWidth: 560, minHeight: 500, maxHeight: 900)
    }
}
