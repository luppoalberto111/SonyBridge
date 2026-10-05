import AppKit
import Bridge
import Client
import ComposableArchitecture
import SwiftUI

@testable import SonyHeadphonesClient

/// Deterministic `HeadphonesState` values shared by the snapshot tests.
enum SnapshotFixtures {
    /// Wraps a SwiftUI view for image snapshotting on macOS.
    ///
    /// swift-snapshot-testing only ships `NSView`/`NSViewController` image
    /// strategies on macOS, so views go through an `NSHostingController`
    /// upcast to `NSViewController`. The color scheme is pinned to Dark so
    /// references stay deterministic regardless of the host Mac's setting.
    @MainActor static func hostingController(_ view: some View) -> NSViewController {
        NSHostingController(rootView: AnyView(view.preferredColorScheme(.dark)))
    }

    static func singleBatteryHeadphones() -> HeadphonesState {
        var state = HeadphonesState()
        state.connected = true
        state.deviceName = "WH-1000XM5"
        state.batteryLevel = 80
        state.codec = "LDAC"
        state.firmware = "2.0.0"
        state.protocolVersion = "v2"
        state.deviceMac = "AA:BB:CC:DD:EE:FF"
        state.supportsEqualizer = true
        state.eqPreset = EqPreset.excited.rawValue
        state.hasAdaptiveVolume = true
        state.adaptiveVolume = true
        state.hasSpeakToChat = true
        state.hasAutoPowerOff = true
        state.autoPowerOff = AutoPowerOffOption.thirtyMinutes.rawValue
        return state
    }

    static func dualBatteryHeadphones() -> HeadphonesState {
        var state = HeadphonesState()
        state.connected = true
        state.deviceName = "WF-1000XM5"
        state.hasDualBattery = true
        state.batteryLeft = 80
        state.batteryRight = 75
        state.batteryCase = 50
        state.batteryLevel = -1
        state.codec = "AAC"
        return state
    }

    static func disconnectedStore() -> StoreOf<DisconnectedReducer> {
        Store(initialState: DisconnectedReducer.State()) {
            DisconnectedReducer()
        }
    }

    static func connectingStore() -> StoreOf<DisconnectedReducer> {
        Store(initialState: DisconnectedReducer.State(connecting: true)) {
            DisconnectedReducer()
        }
    }

    static func deviceListStore() -> StoreOf<DisconnectedReducer> {
        Store(
            initialState: DisconnectedReducer.State(
                devices: [
                    DiscoveredDevice(name: "WH-1000XM5", address: "AA:BB:CC:DD:EE:FF"),
                    DiscoveredDevice(name: "WF-1000XM5", address: "11:22:33:44:55:66"),
                ]
            )
        ) {
            DisconnectedReducer()
        }
    }

    static func errorStore() -> StoreOf<DisconnectedReducer> {
        Store(initialState: DisconnectedReducer.State(errorMessage: "Could not connect.")) {
            DisconnectedReducer()
        }
    }

    static func ambientStore(
        mode: SHCAmbientMode,
        focusOnVoiceAvailable: Bool = false
    ) -> StoreOf<AmbientReducer> {
        Store(
            initialState: AmbientReducer.State(
                mode: mode,
                ambientLevel: 10,
                maxAmbientLevel: 20,
                focusOnVoice: false,
                focusOnVoiceAvailable: focusOnVoiceAvailable
            )
        ) {
            AmbientReducer()
        }
    }

    static func equalizerStore(preset: EqPreset) -> StoreOf<EqualizerReducer> {
        Store(
            initialState: EqualizerReducer.State(
                eqPreset: preset.rawValue,
                eqBands: [2, -1, 0, 3, -2],
                clearBass: 5
            )
        ) {
            EqualizerReducer()
        }
    }

    static func settingsStore() -> StoreOf<SettingsReducer> {
        Store(
            initialState: SettingsReducer.State(
                hasAdaptiveVolume: true,
                adaptiveVolume: true,
                hasSpeakToChat: true,
                speakToChat: false,
                hasAutoPowerOff: true,
                autoPowerOff: .thirtyMinutes
            )
        ) {
            SettingsReducer()
        }
    }

    static func deviceHeroStore(
        headphones: HeadphonesState
    ) -> StoreOf<DeviceHeroReducer> {
        Store(initialState: DeviceHeroReducer.State(headphones: headphones)) {
            DeviceHeroReducer()
        }
    }

    static func connectedStore(
        headphones: HeadphonesState
    ) -> StoreOf<ConnectedReducer> {
        Store(
            initialState: ConnectedReducer.State(
                headphones: headphones,
                deviceHero: DeviceHeroReducer.State(headphones: headphones)
            )
        ) {
            ConnectedReducer()
        }
    }

    static func mainScreenStore(
        state: MainScreenFeature.State
    ) -> StoreOf<MainScreenFeature> {
        Store(initialState: state) {
            MainScreenFeature()
        }
    }
}
