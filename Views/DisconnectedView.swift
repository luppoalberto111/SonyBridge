import Client
import ComposableArchitecture
import Dependencies
import Foundation
import SwiftUI

// MARK: - DisconnectedReducer

@Reducer struct DisconnectedReducer {
    @ObservableState struct State: Equatable {
        var connecting = false
        var errorMessage: String?
        var devices: [DiscoveredDevice] = []
    }

    enum Action {
        case connectButtonTapped
        case autoConnectResponse(HeadphonesState)
        case devicesResponse([DiscoveredDevice])
        case deviceTapped(DiscoveredDevice)
        case connectionResponse(HeadphonesState)
        case delegate(Delegate)
    }

    enum Delegate {
        case didConnect(HeadphonesState)
    }

    @Dependency(\.headphonesClient)
    var client

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case .connectButtonTapped:
                    state.connecting = true
                    state.errorMessage = nil
                    state.devices = []
                    return .run { send in
                        await send(.autoConnectResponse(client.connectToAutoDevice()))
                    }

                case let .autoConnectResponse(snap):
                    if snap.connected {
                        state.connecting = false
                        return .send(.delegate(.didConnect(snap)))
                    }
                    state.connecting = false
                    return .run { send in
                        await send(.devicesResponse(client.pairedDevices()))
                    }

                case let .devicesResponse(devices):
                    state.devices = devices
                    if devices.isEmpty {
                        state.errorMessage = String(
                            localized: "DisconnectedView.emptyListHint",
                            // swiftlint:disable:next line_length
                            defaultValue: "No paired Sony headphones found. Pair them in macOS Bluetooth settings first."
                        )
                    }
                    return .none

                case let .deviceTapped(device):
                    state.connecting = true
                    state.errorMessage = nil
                    return .run { send in
                        await send(.connectionResponse(client.connect(address: device.address)))
                    }

                case let .connectionResponse(snap):
                    state.connecting = false
                    if snap.connected {
                        state.devices = []
                        return .send(.delegate(.didConnect(snap)))
                    }
                    state.errorMessage = snap.errorMessage
                    return .none

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - DisconnectedView

struct DisconnectedView: View {
    let store: StoreOf<DisconnectedReducer>

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "headphones")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(Color(.secondary))
            Text("DisconnectedView.title")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.secondary))
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            if !store.devices.isEmpty {
                deviceList
            }
            Button(action: { store.send(.connectButtonTapped) }) {
                Text(store.connecting ? "DisconnectedView.connecting" : "DisconnectedView.connect")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.accent))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(store.connecting)
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DisconnectedView.devicesTitle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.secondary))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            ForEach(store.devices) { device in
                Button(action: { store.send(.deviceTapped(device)) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(.foreground))
                            Text(device.address)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(Color(.secondary))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(.secondary))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(store.connecting)
            }
        }
        .background(Color(.card))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 40)
    }
}

#Preview {
    DisconnectedView(
        store: Store(initialState: DisconnectedReducer.State(connecting: true)) {
            DisconnectedReducer()
        }
    )
}

#Preview {
    DisconnectedView(
        store: Store(initialState: DisconnectedReducer.State(errorMessage: "Error")) {
            DisconnectedReducer()
        }
    )
}

#Preview {
    DisconnectedView(
        store: Store(
            initialState: DisconnectedReducer.State(
                devices: [
                    DiscoveredDevice(name: "WH-1000XM5", address: "AA:BB:CC:DD:EE:FF"),
                    DiscoveredDevice(name: "WF-1000XM5", address: "11:22:33:44:55:66"),
                ]
            )
        ) {
            DisconnectedReducer()
        }
    )
}
