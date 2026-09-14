import SwiftUI

struct SettingsView: View {
    struct Model {
        let hasAdaptiveVolume: Bool
        let adaptiveVolume: Bool
        let hasSpeakToChat: Bool
        let speakToChat: Bool
        let hasAutoPowerOff: Bool
        let autoPowerOff: AutoPowerOffOption
    }

    let model: Model

    var setAdaptiveVolume: (Bool) -> Void = { _ in }
    var setSpeakToChat: (Bool) -> Void = { _ in }
    var setAutoPowerOff: (AutoPowerOffOption) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SettingsView.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            if model.hasAdaptiveVolume {
                settingToggle("SettingsView.adaptiveVolume.title", "SettingsView.adaptiveVolume.subtitle",
                              on: model.adaptiveVolume, action: setAdaptiveVolume)
            }
            if model.hasSpeakToChat {
                settingToggle("SettingsView.speakToChat.title", "SettingsView.speakToChat.subtitle",
                              on: model.speakToChat, action: setSpeakToChat)
            }
            if model.hasAutoPowerOff {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SettingsView.autoPowerOff.title").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        Text("SettingsView.autoPowerOff.subtitle").font(.system(size: 11)).foregroundColor(Theme.secondary)
                    }
                    Spacer()
                    Picker("", selection: Binding(
                        get: { model.autoPowerOff },
                        set: { setAutoPowerOff($0) }
                    )) {
                        ForEach(AutoPowerOffOption.allCases) { option in Text(option.label).tag(option) }
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

    private func settingToggle(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey, on: Bool, action: @escaping (Bool) -> Void) -> some View {
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
        model: .init(
            hasAdaptiveVolume: true,
            adaptiveVolume: true,
            hasSpeakToChat: true,
            speakToChat: false,
            hasAutoPowerOff: true,
            autoPowerOff: .thirtyMinutes
        )
    )
}

#Preview {
    SettingsView(
        model: .init(
            hasAdaptiveVolume: false,
            adaptiveVolume: false,
            hasSpeakToChat: true,
            speakToChat: true,
            hasAutoPowerOff: false,
            autoPowerOff: .off
        )
    )
}
