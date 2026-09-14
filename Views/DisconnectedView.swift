import Client
import SwiftUI

struct DisconnectedView: View {
    let connecting: Bool
    var errorMessage: String?
    var devices: [DiscoveredDevice] = []
    var connectAction: () -> Void = {}
    var selectAction: (DiscoveredDevice) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "headphones")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(Theme.secondary)
            Text("DisconnectedView.title")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.secondary)
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            if !devices.isEmpty {
                deviceList
            }
            Button(action: connectAction) {
                Text(connecting ? "DisconnectedView.connecting" : "DisconnectedView.connect")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(connecting)
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DisconnectedView.devicesTitle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            ForEach(devices) { device in
                Button(action: { selectAction(device) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Text(device.address)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(Theme.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(connecting)
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 40)
    }
}

#Preview {
    DisconnectedView(connecting: false, errorMessage: "Error")
}

#Preview {
    DisconnectedView(connecting: true, errorMessage: "Error")
}

#Preview {
    DisconnectedView(
        connecting: false,
        devices: [
            DiscoveredDevice(name: "WH-1000XM5", address: "AA:BB:CC:DD:EE:FF"),
            DiscoveredDevice(name: "WF-1000XM5", address: "11:22:33:44:55:66"),
        ]
    )
}
