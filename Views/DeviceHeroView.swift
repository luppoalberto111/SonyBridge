import Client
import ComposableArchitecture
import SwiftUI

// MARK: - DeviceHeroReducer

@Reducer struct DeviceHeroReducer {
    @ObservableState struct State: Equatable {
        var headphones = HeadphonesState()
        var showAbout = false
    }

    enum Action {
        case showAboutChanged(Bool)
        case disconnectTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case disconnectRequested
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .showAboutChanged(show):
                    state.showAbout = show
                    return .none

                case .disconnectTapped:
                    return .send(.delegate(.disconnectRequested))

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - DeviceHeroView

struct DeviceHeroView: View {
    /// Render bundle derived from `HeadphonesState` (see `deviceHeroModel`).
    /// Separate from `DeviceHeroReducer.State`, which owns behavior state.
    struct Model {
        let deviceName: String
        let deviceImage: Image?
        let hasDualBattery: Bool
        let batteryLeft: Int
        let batteryRight: Int
        let batteryLevel: Int
        let batteryImage: Image
        let codec: String
        let about: AboutView.Model
    }

    let store: StoreOf<DeviceHeroReducer>

    var body: some View {
        let model = store.headphones.deviceHeroModel
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Spacer()
                Button(action: { store.send(.showAboutChanged(true)) }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.card)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .popover(
                    isPresented: Binding(
                        get: { store.showAbout },
                        set: { store.send(.showAboutChanged($0)) }
                    ),
                    arrowEdge: .bottom
                ) {
                    AboutView(model: model.about)
                }
                Button(action: { store.send(.disconnectTapped) }) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.card)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Product-style banner. Generic headphone graphic (device-specific Sony renders are
            // copyrighted and can't be bundled) over a soft accent halo, mirroring Sony's app layout.
            ZStack {
                // Soft accent glow behind the product for depth.
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.accent.opacity(0.22),
                                Theme.accent.opacity(0.0)
                            ]),
                            center: .center, startRadius: 4, endRadius: 104
                        )
                    )
                    .frame(width: 210, height: 210)

                if let image = model.deviceImage {
                    // Background-removed product cutout floating on the dark UI.
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 190, height: 190)
                } else {
                    Image(systemName: "headphones")
                        .font(.system(size: 92, weight: .thin))
                        .foregroundColor(.white)
                }
            }

            Text(model.deviceName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 7) {
                if model.hasDualBattery {
                    Image(systemName: "battery.100")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.accent)
                    Text(String(
                        format: String(
                            localized: "DeviceHeroView.batteryDual.value",
                            defaultValue: "L %@  R %@"
                        ),
                        model.batteryLeft.percentFormatted,
                        model.batteryRight.percentFormatted
                    ))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.secondary)
                } else if model.batteryLevel >= 0 {
                    model.batteryImage
                        .font(.system(size: 13))
                        .foregroundColor(model.batteryLevel <= 20 ? .red.opacity(0.9) : Theme
                            .accent)
                    Text(model.batteryLevel.percentFormatted)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                } else {
                    Circle().fill(Theme.accent).frame(width: 7, height: 7)
                    Text("DeviceHeroView.status.connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.secondary)
                }
                if !model.codec.isEmpty {
                    Text("·").foregroundColor(Theme.secondary)
                    Text(model.codec)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private func previewHeadphones() -> HeadphonesState {
    var state = HeadphonesState()
    state.connected = true
    state.deviceName = "WH-1000XM5"
    state.batteryLevel = 80
    state.codec = "LDAC"
    state.firmware = "2.0.0"
    state.protocolVersion = "v2"
    state.deviceMac = "AA:BB:CC:DD:EE:FF"
    return state
}

#Preview {
    DeviceHeroView(
        store: Store(initialState: DeviceHeroReducer.State(headphones: previewHeadphones())) {
            DeviceHeroReducer()
        }
    )
}

#Preview {
    var dual = previewHeadphones()
    dual.deviceName = "WF-1000XM5"
    dual.hasDualBattery = true
    dual.batteryLeft = 80
    dual.batteryRight = 75
    dual.batteryCase = 50
    dual.batteryLevel = -1
    dual.codec = ""
    return DeviceHeroView(
        store: Store(initialState: DeviceHeroReducer.State(headphones: dual)) {
            DeviceHeroReducer()
        }
    )
}
