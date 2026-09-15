import Client
import ComposableArchitecture
import SwiftUI

// MARK: - SettingsReducer

@Reducer struct SettingsReducer {
    @ObservableState struct State: Equatable {
        var hasAdaptiveVolume = false
        var adaptiveVolume = false
        var hasSpeakToChat = false
        var speakToChat = false
        var hasAutoPowerOff = false
        var autoPowerOff = AutoPowerOffOption.off

        mutating func sync(from headphones: HeadphonesState) {
            hasAdaptiveVolume = headphones.hasAdaptiveVolume
            adaptiveVolume = headphones.adaptiveVolume
            hasSpeakToChat = headphones.hasSpeakToChat
            speakToChat = headphones.speakToChat
            hasAutoPowerOff = headphones.hasAutoPowerOff
            autoPowerOff = AutoPowerOffOption(rawValue: headphones.autoPowerOff) ?? .off
        }
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
        Reduce { state, action in
            switch action {
                case let .setAdaptiveVolume(on):
                    state.adaptiveVolume = on
                    return .send(.delegate(.setAdaptiveVolume(on)))

                case let .setSpeakToChat(on):
                    state.speakToChat = on
                    return .send(.delegate(.setSpeakToChat(on)))

                case let .setAutoPowerOff(option):
                    state.autoPowerOff = option
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
                .foregroundColor(.white)
            if store.hasAdaptiveVolume {
                settingToggle(
                    "SettingsView.adaptiveVolume.title",
                    "SettingsView.adaptiveVolume.subtitle",
                    on: store.adaptiveVolume
                ) { store.send(.setAdaptiveVolume($0)) }
            }
            if store.hasSpeakToChat {
                settingToggle(
                    "SettingsView.speakToChat.title",
                    "SettingsView.speakToChat.subtitle",
                    on: store.speakToChat
                ) { store.send(.setSpeakToChat($0)) }
            }
            if store.hasAutoPowerOff {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SettingsView.autoPowerOff.title")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("SettingsView.autoPowerOff.subtitle")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.secondary)
                    }
                    Spacer()
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.autoPowerOff },
                            set: { store.send(.setAutoPowerOff($0)) }
                        )
                    ) {
                        ForEach(AutoPowerOffOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 130)
                    .accentColor(Theme.accent)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingToggle(
        _ title: LocalizedStringKey,
        _ subtitle: LocalizedStringKey,
        on: Bool,
        action: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: Binding(get: { on }, set: { action($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 11)).foregroundColor(Theme.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
    }
}

#Preview {
    SettingsView(
        store: Store(
            initialState: SettingsReducer.State(
                hasAdaptiveVolume: true,
                adaptiveVolume: true,
                hasSpeakToChat: true,
                speakToChat: false,
                hasAutoPowerOff: true,
                autoPowerOff: .thirtyMinutes
            )
        ) {
            SettingsReducer()
        }
    )
}

#Preview {
    SettingsView(
        store: Store(
            initialState: SettingsReducer.State(
                hasAdaptiveVolume: false,
                adaptiveVolume: false,
                hasSpeakToChat: true,
                speakToChat: true,
                hasAutoPowerOff: false,
                autoPowerOff: .off
            )
        ) {
            SettingsReducer()
        }
    )
}
