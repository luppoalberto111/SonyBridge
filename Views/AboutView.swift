import SwiftUI

struct AboutView: View {
    struct Model {
        let deviceName: String
        let connected: Bool
        let hasDualBattery: Bool
        let batteryLeft: Int
        let batteryRight: Int
        let batteryCase: Int
        let batteryLevel: Int
        let batteryCharging: Bool
        let codec: String
        let firmware: String
        let protocolVersion: String
        let deviceMac: String
    }

    let model: Model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.deviceName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            aboutRow("AboutView.row.status", model.connected
                ? String(localized: "AboutView.status.connected", defaultValue: "Connected")
                : String(localized: "AboutView.status.disconnected", defaultValue: "Disconnected"))
            if model.hasDualBattery {
                aboutRow("AboutView.row.batteryDual", String(
                    format: String(localized: "AboutView.batteryDual.value", defaultValue: "%@ / %@"),
                    model.batteryLeft.percentFormatted, model.batteryRight.percentFormatted))
                if model.batteryCase >= 0 {
                    aboutRow("AboutView.row.batteryCase", model.batteryCase.percentFormatted)
                }
            } else if model.batteryLevel >= 0 {
                let chargingSuffix = model.batteryCharging
                    ? String(localized: "AboutView.batterySingle.chargingSuffix", defaultValue: " (charging)")
                    : ""
                aboutRow("AboutView.row.batterySingle",
                    model.batteryLevel.percentFormatted + chargingSuffix)
            }
            if !model.codec.isEmpty { aboutRow("AboutView.row.codec", model.codec) }
            if !model.firmware.isEmpty { aboutRow("AboutView.row.firmware", model.firmware) }
            if !model.protocolVersion.isEmpty { aboutRow("AboutView.row.protocol", model.protocolVersion) }
            if !model.deviceMac.isEmpty { aboutRow("AboutView.row.bluetooth", model.deviceMac) }
            Divider().background(Theme.cardHi).padding(.vertical, 10)
            Text("AboutView.disclaimer")
                .font(.system(size: 10))
                .foregroundColor(Theme.secondary.opacity(0.7))
        }
        .padding(18)
        .frame(width: 260)
        .background(Theme.card)
    }

    private func aboutRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(Theme.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    AboutView(
        model: .init(
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
    )
}

#Preview {
    AboutView(
        model: .init(
            deviceName: "WF-1000XM5",
            connected: true,
            hasDualBattery: true,
            batteryLeft: 80,
            batteryRight: 75,
            batteryCase: 50,
            batteryLevel: -1,
            batteryCharging: false,
            codec: "AAC",
            firmware: "",
            protocolVersion: "",
            deviceMac: ""
        )
    )
}
