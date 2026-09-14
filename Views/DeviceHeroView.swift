import SwiftUI

// MARK: - DeviceHeroView

struct DeviceHeroView: View {
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

    let model: Model

    @Binding
    var showAbout: Bool
    var disconnect: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Spacer()
                Button(action: { showAbout = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.card)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showAbout, arrowEdge: .bottom) {
                    AboutView(model: model.about)
                }
                Button(action: disconnect) {
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

private func aboutPreviewModel() -> AboutView.Model {
    .init(
        deviceName: "WH-1000XM5",
        connected: true,
        hasDualBattery: false,
        batteryLeft: -1,
        batteryRight: -1,
        batteryCase: -1,
        batteryLevel: 80,
        batteryCharging: false,
        codec: "LDAC",
        firmware: "2.0.0",
        protocolVersion: "v2",
        deviceMac: "AA:BB:CC:DD:EE:FF"
    )
}

#Preview {
    DeviceHeroView(
        model: .init(
            deviceName: "WH-1000XM5",
            deviceImage: nil,
            hasDualBattery: false,
            batteryLeft: -1,
            batteryRight: -1,
            batteryLevel: 80,
            batteryImage: Image(systemName: "battery.100"),
            codec: "LDAC",
            about: aboutPreviewModel()
        ),
        showAbout: .constant(false)
    )
}

#Preview {
    DeviceHeroView(
        model: .init(
            deviceName: "WF-1000XM5",
            deviceImage: nil,
            hasDualBattery: true,
            batteryLeft: 80,
            batteryRight: 75,
            batteryLevel: -1,
            batteryImage: Image(systemName: "battery.100"),
            codec: "",
            about: aboutPreviewModel()
        ),
        showAbout: .constant(false)
    )
}
