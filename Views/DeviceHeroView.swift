import Client
import ComposableArchitecture
import SwiftUI

// MARK: - DeviceHeroReducer

@Reducer struct DeviceHeroReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var headphones: SonyHeadphones
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
                        .foregroundColor(.foregroundSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.card)
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
                        .foregroundColor(.foregroundSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.card))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.highlight.opacity(0.22),
                                Color.highlight.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 4,
                            endRadius: 104
                        )
                    )
                    .frame(width: 210, height: 210)

                if let image = model.deviceImage {
                    // Background-removed product cutout floating on the dark UI.
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 190)
                } else {
                    Image(systemName: "headphones")
                        .font(.system(size: 92, weight: .thin))
                        .foregroundColor(.foreground)
                }
            }

            Text(model.deviceName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.foreground)

            HStack(spacing: 7) {
                if model.hasDualBattery {
                    Image(systemName: "battery.100")
                        .font(.system(size: 13))
                        .foregroundColor(.highlight)
                    Text(String(
                        format: String(
                            localized: "DeviceHeroView.batteryDual.value",
                            defaultValue: "L %@  R %@"
                        ),
                        model.batteryLeft.percentFormatted,
                        model.batteryRight.percentFormatted
                    ))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.foregroundSecondary)
                } else if model.batteryLevel >= 0 {
                    model.batteryImage
                        .font(.system(size: 13))
                        .foregroundColor(model.batteryLevel <= 20 ? .red
                            .opacity(0.9) : Color(.highlight))
                    Text(model.batteryLevel.percentFormatted)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.foregroundSecondary)
                } else {
                    Circle().fill(Color(.highlight)).frame(width: 7, height: 7)
                    Text("DeviceHeroView.status.connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.foregroundSecondary)
                }
                if !model.codec.isEmpty {
                    Text("·").foregroundColor(.foregroundSecondary)
                    Text(model.codec)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.foregroundSecondary)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private func previewHeadphones() -> SonyHeadphones {
    SonyHeadphones(
        connected: true,
        deviceModel: .left(.wh1000Xm5),
        batteryLevel: 80,
        firmware: "2.0.0",
        codec: "LDAC",
        deviceMac: "AA:BB:CC:DD:EE:FF",
        protocolVersion: "v2"
    )
}

#Preview {
    DeviceHeroView(
        store: Store(
            initialState: .init(headphones: .init(value: previewHeadphones())),
            reducer: DeviceHeroReducer.init
        )
    )
}

// (preview removed)
