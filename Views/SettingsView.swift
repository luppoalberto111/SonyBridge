import Client
import ComposableArchitecture
import SwiftUI

// MARK: - SettingsReducer

@Reducer struct SettingsReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var headphones: SonyHeadphones
        @Shared
        var uiState: HeadphonesUIState
        var adaptiveVolumeLoading = false
        var autoPowerOffLoading = false
        var speakToChatLoading = false
    }

    enum Action {
        case setAdaptiveVolume(Bool)
        case setSpeakToChat(Bool)
        case setAutoPowerOff(AutoPowerOffOption)
        case delegate(Delegate)
    }

    enum Delegate {
        case setAdaptiveVolume(Bool)
        case setSpeakToChat(Bool)
        case setAutoPowerOff(AutoPowerOffOption)
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
                case let .setAdaptiveVolume(on):
                    return .send(.delegate(.setAdaptiveVolume(on)))

                case let .setSpeakToChat(on):
                    return .send(.delegate(.setSpeakToChat(on)))

                case let .setAutoPowerOff(option):
                    return .send(.delegate(.setAutoPowerOff(option)))

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    let store: StoreOf<SettingsReducer>

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SettingsView.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(.foreground))
            if store.headphones.hasAdaptiveVolume {
                settingToggle(
                    "SettingsView.adaptiveVolume.title",
                    "SettingsView.adaptiveVolume.subtitle",
                    on: store.headphones.adaptiveVolume,
                    loading: store.adaptiveVolumeLoading
                ) { store.send(.setAdaptiveVolume($0)) }
            }
            if store.headphones.hasSpeakToChat {
                settingToggle(
                    "SettingsView.speakToChat.title",
                    "SettingsView.speakToChat.subtitle",
                    on: store.headphones.speakToChat
                ) {
                    store.send(.setSpeakToChat($0))
                }
                .disabled(store.speakToChatLoading)
                if store.speakToChatLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            if store.headphones.hasAutoPowerOff {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SettingsView.autoPowerOff.title")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.foreground))
                        Text("SettingsView.autoPowerOff.subtitle")
                            .font(.system(size: 11))
                            .foregroundColor(Color(.foregroundSecondary))
                    }
                    Spacer()
                    if store.uiState.autoPowerOffLoading {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.headphones.autoPowerOff },
                            set: { store.send(.setAutoPowerOff(.init(rawValue: $0) ?? .off)) }
                        )
                    ) {
                        ForEach(AutoPowerOffOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 130)
                    .accentColor(.highlight)
                    .disabled(store.uiState.autoPowerOffLoading)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingToggle(
        _ title: LocalizedStringKey,
        _ subtitle: LocalizedStringKey,
        on: Bool,
        loading: Bool = false,
        action: @escaping (Bool) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(get: { on }, set: { action($0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.foreground)
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.foregroundSecondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .highlight))
            .disabled(loading)

            if loading {
                ProgressView()
                    .controlSize(.mini)
            }
        }
    }
}

#Preview {
    SettingsView(
        store: Store(
            initialState: .init(
                headphones: Shared(
                    value: .init(
                        hasAutoPowerOff: true,
                        autoPowerOff: 2,
                        hasSpeakToChat: true,
                        speakToChat: false,
                        hasAdaptiveVolume: true,
                        adaptiveVolume: true,
                    )
                ),
                uiState: .init(value: .init())
            ),
            reducer: SettingsReducer.init
        )
    )
}

#Preview {
    SettingsView(
        store: Store(
            initialState: .init(
                headphones: Shared(
                    value: .init(
                        hasAutoPowerOff: false,
                        autoPowerOff: 0,
                        hasSpeakToChat: true,
                        speakToChat: true,
                        hasAdaptiveVolume: false,
                        adaptiveVolume: false
                    )
                ),
                uiState: .init(value: .init())
            ),
            reducer: SettingsReducer.init
        )
    )
}
