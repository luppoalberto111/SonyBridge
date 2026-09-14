import SwiftUI

struct MainScreenView: View {
    @StateObject
    private var model: MainScreenViewModel

    init(viewModel: MainScreenViewModel) {
        _model = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if model.state.connected {
                ConnectedView(
                    state: model.state,
                    showAbout: $model.showAbout,
                    disconnect: model.disconnect,
                    setMode: model.setMode,
                    setLevel: model.setLevel,
                    setFocusOnVoice: model.setFocusOnVoice,
                    setEqualizer: model.setEqualizer,
                    setBand: model.setBand,
                    setClearBass: model.setClearBass,
                    setDsee: model.setDsee,
                    setAdaptiveVolume: model.setAdaptiveVolume,
                    setSpeakToChat: model.setSpeakToChat,
                    setAutoPowerOff: model.setAutoPowerOff
                )
            } else {
                DisconnectedView(
                    connecting: model.state.connecting,
                    errorMessage: model.state.errorMessage,
                    devices: model.availableDevices,
                    connectAction: model.connect,
                    selectAction: model.selectDevice
                )
            }
        }
        .frame(minWidth: 360, maxWidth: 560, minHeight: 500, maxHeight: 900)
    }
}
