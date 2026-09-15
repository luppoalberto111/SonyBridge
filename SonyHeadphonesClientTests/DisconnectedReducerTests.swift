import Client
import ComposableArchitecture
import Testing

@testable import SonyHeadphonesClient

@MainActor struct DisconnectedReducerTests {
    @Test func autoConnectSuccessDelegatesDidConnect() async {
        var connected = HeadphonesState()
        connected.connected = true
        connected.deviceName = "WH-1000XM5"

        let store = TestStore(initialState: DisconnectedReducer.State()) {
            DisconnectedReducer()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient(state: connected)
        }

        await store.send(.connectButtonTapped) {
            $0.connecting = true
        }
        await store.receive(\.autoConnectResponse) {
            $0.connecting = false
        }
        await store.receive(\.delegate)
    }

    @Test func emptyDeviceListShowsHint() async {
        let store = TestStore(initialState: DisconnectedReducer.State()) {
            DisconnectedReducer()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient()
        }

        await store.send(.connectButtonTapped) {
            $0.connecting = true
        }
        await store.receive(\.autoConnectResponse) {
            $0.connecting = false
        }
        await store.receive(\.devicesResponse) {
            $0.errorMessage = String(
                localized: "DisconnectedView.emptyListHint",
                defaultValue: "No paired Sony headphones found. Pair them in macOS Bluetooth settings first."
            )
        }
    }

    @Test func deviceTappedConnectsToThatAddress() async {
        let device = DiscoveredDevice(name: "WH-1000XM5", address: "AA:BB:CC:DD:EE:FF")
        let client = HeadphonesTestClient()
        await client.setStubbedDevices([device])

        let store = TestStore(
            initialState: DisconnectedReducer.State(devices: [device])
        ) {
            DisconnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.deviceTapped(device)) {
            $0.connecting = true
            $0.errorMessage = nil
        }
        await store.receive(\.connectionResponse) {
            $0.connecting = false
            $0.devices = []
        }
        await store.receive(\.delegate)
    }

    @Test func failedConnectionSurfacesErrorMessage() async {
        let device = DiscoveredDevice(name: "WH-1000XM5", address: "AA:BB:CC:DD:EE:FF")
        let client = HeadphonesTestClient()
        await client.setStubbedDevices([device])
        await client.setConnectionError("Could not connect.")

        let store = TestStore(
            initialState: DisconnectedReducer.State(devices: [device])
        ) {
            DisconnectedReducer()
        } withDependencies: {
            $0.headphonesClient = client
        }

        await store.send(.deviceTapped(device)) {
            $0.connecting = true
            $0.errorMessage = nil
        }
        await store.receive(\.connectionResponse) {
            $0.connecting = false
            $0.errorMessage = "Could not connect."
        }
    }

    @Test func connectButtonTappedStartsConnectingAndClearsPreviousError() async {
        let store = TestStore(
            initialState: DisconnectedReducer.State(errorMessage: "Boom")
        ) {
            DisconnectedReducer()
        } withDependencies: {
            $0.headphonesClient = HeadphonesTestClient()
        }

        await store.send(.connectButtonTapped) {
            $0.connecting = true
            $0.errorMessage = nil
            $0.devices = []
        }
        await store.receive(\.autoConnectResponse) {
            $0.connecting = false
        }
        await store.receive(\.devicesResponse)
    }
}
