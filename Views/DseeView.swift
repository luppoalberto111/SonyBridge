import ComposableArchitecture
import SwiftUI

// MARK: - DseeReducer

@Reducer struct DseeReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var uiState: HeadphonesUIState
    }

    enum Action {
        case setDsee(Bool)
        case delegate(Delegate)
    }

    enum Delegate {
        case setDsee(Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
                case let .setDsee(on):
                    return .send(.delegate(.setDsee(on)))

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - DseeView

struct DseeView: View {
    let store: StoreOf<DseeReducer>

    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(
                get: { store.uiState.dsee },
                set: { store.send(.setDsee($0)) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DseeView.title").font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.foreground))
                    Text("DseeView.subtitle").font(.system(size: 11))
                        .foregroundColor(Color(.foregroundSecondary))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.highlight))
            .disabled(store.uiState.dseeLoading)

            if store.uiState.dseeLoading {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    DseeView(
        store: Store(
            initialState: .init(
                uiState: .init(value: HeadphonesUIState(dsee: true))
            ),
            reducer: DseeReducer.init
        )
    )
}

#Preview {
    DseeView(
        store: Store(
            initialState: .init(
                uiState: .init(value: HeadphonesUIState(dsee: false))
            ),
            reducer: DseeReducer.init
        )
    )
}
