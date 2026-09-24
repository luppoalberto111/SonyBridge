import Client
import ComposableArchitecture
import SwiftUI

// MARK: - DseeReducer

@Reducer struct DseeReducer {
    @ObservableState struct State: Equatable {
        var dsee = false

        mutating func sync(from headphones: HeadphonesState) {
            dsee = headphones.dsee
        }
    }

    enum Action {
        case setDsee(Bool)
        case delegate(Delegate)
    }

    enum Delegate {
        case setDsee(Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .setDsee(on):
                    state.dsee = on
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
        Toggle(isOn: Binding(
            get: { store.dsee },
            set: { store.send(.setDsee($0)) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DseeView.title").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("DseeView.subtitle").font(.system(size: 11))
                    .foregroundColor(Color(.secondary))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(.accent)))
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.card))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    DseeView(
        store: Store(initialState: DseeReducer.State(dsee: true)) {
            DseeReducer()
        }
    )
}

#Preview {
    DseeView(
        store: Store(initialState: DseeReducer.State(dsee: false)) {
            DseeReducer()
        }
    )
}
