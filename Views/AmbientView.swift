import Bridge
import SwiftUI

struct AmbientView: View {
    struct Model {
        let mode: SHCAmbientMode
        let ambientLevel: Int
        let maxAmbientLevel: Int
        let focusOnVoice: Bool
        let focusOnVoiceAvailable: Bool
    }

    let model: Model

    var setMode: (SHCAmbientMode) -> Void = { _ in }
    var setLevel: (Int) -> Void = { _ in }
    var setFocusOnVoice: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 16) {
            modeCard
            if model.mode == .ambientSound {
                levelCard
            }
        }
    }

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AmbientView.modeCard.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            HStack(spacing: 0) {
                ModeButton(
                    mode: .noiseCanceling,
                    isSelected: model.mode == .noiseCanceling,
                    setMode: setMode
                )
                ModeButton(
                    mode: .ambientSound,
                    isSelected: model.mode == .ambientSound,
                    setMode: setMode
                )
                ModeButton(
                    mode: .off,
                    isSelected: model.mode == .off,
                    setMode: setMode
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("AmbientView.levelCard.title")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.secondary)
                Spacer()
                Text("\(model.ambientLevel)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
            }
            Slider(
                value: Binding(
                    get: { Double(model.ambientLevel) },
                    set: { setLevel(Int($0.rounded())) }
                ),
                in: 1 ... Double(model.maxAmbientLevel),
                step: 1
            )
            .accentColor(Theme.accent)

            if model.focusOnVoiceAvailable {
                Toggle(isOn: Binding(
                    get: { model.focusOnVoice },
                    set: { setFocusOnVoice($0) }
                )) {
                    Text("AmbientView.levelCard.focusOnVoice")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    AmbientView(
        model: .init(
            mode: .ambientSound,
            ambientLevel: 10,
            maxAmbientLevel: 20,
            focusOnVoice: false,
            focusOnVoiceAvailable: true
        )
    )
}

#Preview {
    AmbientView(
        model: .init(
            mode: .noiseCanceling,
            ambientLevel: 10,
            maxAmbientLevel: 20,
            focusOnVoice: false,
            focusOnVoiceAvailable: false
        )
    )
}
