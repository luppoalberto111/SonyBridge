import SwiftUI
import Bridge
import Client

struct ConnectedView: View {
    let state: HeadphonesState

    @Binding var showAbout: Bool

    var disconnect: () -> Void = {}
    var setMode: (SHCAmbientMode) -> Void = { _ in }
    var setLevel: (Int) -> Void = { _ in }
    var setFocusOnVoice: (Bool) -> Void = { _ in }
    var setEqualizer: (Int) -> Void = { _ in }
    var setBand: (Int, Int) -> Void = { _, _ in }
    var setClearBass: (Int) -> Void = { _ in }
    var setDsee: (Bool) -> Void = { _ in }
    var setAdaptiveVolume: (Bool) -> Void = { _ in }
    var setSpeakToChat: (Bool) -> Void = { _ in }
    var setAutoPowerOff: (AutoPowerOffOption) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                DeviceHeroView(
                    model: state.deviceHeroModel,
                    showAbout: $showAbout,
                    disconnect: disconnect
                )
                AmbientView(
                    model: state.ambientModel,
                    setMode: setMode,
                    setLevel: setLevel,
                    setFocusOnVoice: setFocusOnVoice
                )
                if state.supportsEqualizer {
                    EqualizerView(
                        model: state.equalizerModel,
                        setEqualizer: setEqualizer,
                        setBand: setBand,
                        setClearBass: setClearBass
                    )
                    DseeView(
                        model: state.dseeModel,
                        setDsee: setDsee
                    )
                }
                if state.hasAdaptiveVolume || state.hasSpeakToChat || state.hasAutoPowerOff {
                    SettingsView(
                        model: state.settingsModel,
                        setAdaptiveVolume: setAdaptiveVolume,
                        setSpeakToChat: setSpeakToChat,
                        setAutoPowerOff: setAutoPowerOff
                    )
                }
                if let error = state.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.9))
                }
            }
            .padding(20)
        }
    }
}

private func previewState() -> HeadphonesState {
    var state = HeadphonesState()
    state.connected = true
    state.deviceName = "WH-1000XM5"
    state.batteryLevel = 80
    state.codec = "LDAC"
    state.supportsEqualizer = true
    state.eqPreset = EqPreset.excited.rawValue
    state.hasAdaptiveVolume = true
    state.adaptiveVolume = true
    state.hasSpeakToChat = true
    state.hasAutoPowerOff = true
    state.autoPowerOff = AutoPowerOffOption.thirtyMinutes.rawValue
    return state
}

#Preview {
    ConnectedView(state: previewState(), showAbout: .constant(false))
}

#Preview {
    ConnectedView(state: HeadphonesState(), showAbout: .constant(false))
}
