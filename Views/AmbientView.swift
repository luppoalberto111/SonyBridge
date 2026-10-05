import Bridge
import Client
import ComposableArchitecture
import SwiftUI

// MARK: - AmbientReducer

@Reducer struct AmbientReducer {
    @ObservableState struct State: Equatable {
        var mode: SHCAmbientMode = .off
        var ambientLevel = 10
        var maxAmbientLevel = 20
        var focusOnVoice = false
        var focusOnVoiceAvailable = false

        mutating func sync(from headphones: HeadphonesState) {
            mode = headphones.mode
            ambientLevel = headphones.ambientLevel
            maxAmbientLevel = headphones.maxAmbientLevel
            focusOnVoice = headphones.focusOnVoice
            focusOnVoiceAvailable = headphones.focusOnVoiceAvailable
        }
    }

    enum Action {
        case setMode(SHCAmbientMode)
        case setLevel(Int)
        case setFocusOnVoice(Bool)
        case delegate(Delegate)
    }

    enum Delegate {
        case setMode(SHCAmbientMode)
        case setLevel(Int)
        case setFocusOnVoice(Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .setMode(mode):
                    state.mode = mode
                    return .send(.delegate(.setMode(mode)))

                case let .setLevel(level):
                    state.ambientLevel = level
                    return .send(.delegate(.setLevel(level)))

                case let .setFocusOnVoice(on):
                    state.focusOnVoice = on
                    return .send(.delegate(.setFocusOnVoice(on)))

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - AmbientView

struct AmbientView: View {
    let store: StoreOf<AmbientReducer>

    var body: some View {
        VStack(spacing: 16) {
            modeCard
            if store.mode == .ambientSound {
                levelCard
            }
        }
    }

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AmbientView.modeCard.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(.foreground))
            HStack(spacing: 0) {
                ModeButton(
                    mode: .noiseCanceling,
                    isSelected: store.mode == .noiseCanceling
                ) { store.send(.setMode($0)) }
                ModeButton(
                    mode: .ambientSound,
                    isSelected: store.mode == .ambientSound
                ) { store.send(.setMode($0)) }
                ModeButton(
                    mode: .off,
                    isSelected: store.mode == .off
                ) { store.send(.setMode($0)) }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.card))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("AmbientView.levelCard.title")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.secondary))
                Spacer()
                Text("\(store.ambientLevel)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.accent))
            }
            Slider(
                value: Binding(
                    get: { Double(store.ambientLevel) },
                    set: { store.send(.setLevel(Int($0.rounded()))) }
                ),
                in: 1 ... Double(store.maxAmbientLevel),
                step: 1
            )
            .accentColor(Color(.accent))

            if store.focusOnVoiceAvailable {
                Toggle(isOn: Binding(
                    get: { store.focusOnVoice },
                    set: { store.send(.setFocusOnVoice($0)) }
                )) {
                    Text("AmbientView.levelCard.focusOnVoice")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.foreground))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(.accent)))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.card))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    AmbientView(
        store: Store(
            initialState: AmbientReducer.State(
                mode: .ambientSound,
                ambientLevel: 10,
                maxAmbientLevel: 20,
                focusOnVoice: false,
                focusOnVoiceAvailable: true
            )
        ) {
            AmbientReducer()
        }
    )
}

#Preview {
    AmbientView(
        store: Store(
            initialState: AmbientReducer.State(
                mode: .noiseCanceling,
                ambientLevel: 10,
                maxAmbientLevel: 20,
                focusOnVoice: false,
                focusOnVoiceAvailable: false
            )
        ) {
            AmbientReducer()
        }
    )
}
