import Bridge
import Client
import ComposableArchitecture
import SwiftUI

// MARK: - AmbientReducer

@Reducer struct AmbientReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var headphones: HeadphonesState
        @Shared
        var uiState: HeadphonesUIState
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
        Reduce { _, action in
            switch action {
                case let .setMode(mode):
                    return .send(.delegate(.setMode(mode)))

                case let .setLevel(level):
                    return .send(.delegate(.setLevel(level)))

                case let .setFocusOnVoice(on):
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
            if store.headphones.mode == .ambientSound {
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
                    isSelected: store.headphones.mode == .noiseCanceling
                ) { store.send(.setMode($0)) }
                ModeButton(
                    mode: .ambientSound,
                    isSelected: store.headphones.mode == .ambientSound
                ) { store.send(.setMode($0)) }
                ModeButton(
                    mode: .off,
                    isSelected: store.headphones.mode == .off
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
                    .foregroundColor(Color(.foregroundSecondary))
                Spacer()
                Text("\(store.headphones.ambientLevel)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.highlight))
            }
            Slider(
                value: Binding(
                    get: { Double(store.headphones.ambientLevel) },
                    set: { store.send(.setLevel(Int($0.rounded()))) }
                ),
                in: 1 ... Double(store.headphones.maxAmbientLevel),
                step: 1
            )
            .accentColor(Color(.highlight))

            HStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { store.headphones.focusOnVoice },
                    set: { store.send(.setFocusOnVoice($0)) }
                )) {
                    Text("AmbientView.levelCard.focusOnVoice")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.foreground))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(.highlight)))
                .disabled(store.uiState.focusOnVoiceLoading)

                if store.uiState.focusOnVoiceLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
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
            initialState: .init(
                headphones: Shared(
                    value: .init(
                        maxAmbientLevel: 20,
                        mode: .ambientSound,
                        ambientLevel: 10,
                        focusOnVoice: false,
                        focusOnVoiceAvailable: true
                    )
                ),
                uiState: Shared(value: .init())
            ),
            reducer: AmbientReducer.init
        )
    )
}

#Preview {
    AmbientView(
        store: Store(
            initialState: .init(
                headphones: Shared(
                    value: .init(
                        maxAmbientLevel: 20,
                        mode: .noiseCanceling,
                        ambientLevel: 10,
                        focusOnVoice: false,
                        focusOnVoiceAvailable: false
                    )
                ),
                uiState: Shared(value: .init())
            ),
            reducer: AmbientReducer.init
        )
    )
}
