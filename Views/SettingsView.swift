import Client
import ComposableArchitecture
import SwiftUI

// MARK: - SettingsReducer

@Reducer struct SettingsReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var headphones: HeadphonesState
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

    /// True while the device is still applying an adaptive-volume change; that toggle is disabled
    /// and keeps its previous value until the write is confirmed.
    var adaptiveVolumeLoading = false

    /// True while the device is still applying an auto-power-off change; that picker is disabled
    /// and keeps its previous value until the write is confirmed.
    var autoPowerOffLoading = false

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
                    loading: adaptiveVolumeLoading
                ) { store.send(.setAdaptiveVolume($0)) }
            }
            if store.headphones.hasSpeakToChat {
                settingToggle(
                    "SettingsView.speakToChat.title",
                    "SettingsView.speakToChat.subtitle",
                    on: store.headphones.speakToChat
                ) { store.send(.setSpeakToChat($0)) }
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
                    if autoPowerOffLoading {
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
                    .disabled(autoPowerOffLoading)
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
                )
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
                )
            ),
            reducer: SettingsReducer.init
        )
    )
}
