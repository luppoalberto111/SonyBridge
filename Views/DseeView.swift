import Client
import ComposableArchitecture
import SwiftUI

// MARK: - DseeReducer

@Reducer struct DseeReducer {
    @ObservableState struct State: Equatable {
        var headphones: HeadphonesState

//        init(dsee: Bool = false) {
//            self.dsee = dsee
//        }

//        init(headphones: HeadphonesState) {
//            self.init(dsee: headphones.dsee)
//        }
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
                    state.headphones.dsee = on
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
            get: { store.headphones.dsee },
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    DseeView(
        store: Store(initialState: .init(headphones: .init(dsee: true)), reducer: DseeReducer.init)
    )
}

#Preview {
    DseeView(
        store: Store(initialState: .init(headphones: .init(dsee: false)), reducer: DseeReducer.init)
    )
}
