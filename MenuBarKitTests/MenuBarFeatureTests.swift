import Bridge
import Client
import ComposableArchitecture
@testable import MenuBarKit
import Testing

// MARK: - MenuBarFeatureTests

@MainActor struct MenuBarFeatureTests {
    @Test func quitTappedTerminatesApp() async {
        var didTerminate = false
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient.terminateApp = {
                didTerminate = true
            }
        }

        await store.send(.quitTapped)
        #expect(didTerminate)
    }

    @Test func connectTappedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.connectTapped)
        await store.receive(\.delegate)
    }

    @Test func batteryMenuTitleFormatsKnownAndUnknownLevels() {
        #expect(batteryMenuTitle(level: 80) == "Battery: 80%")
        #expect(batteryMenuTitle(level: 0) == "Battery: 0%")
        #expect(batteryMenuTitle(level: -1) == "Battery: --")
    }

    @Test func disconnectTappedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.disconnectTapped)
        await store.receive(\.delegate)
    }

    @Test func ambientModeTappedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.ambientModeTapped(.noiseCanceling))
        await store.receive(\.delegate)
    }

    @Test func ambientLevelPickedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.ambientLevelPicked(15))
        await store.receive(\.delegate)
    }

    @Test func focusOnVoicePickedEmitsDelegate() async {
        let store = TestStore(initialState: MenuBarFeature.State()) {
            MenuBarFeature()
        } withDependencies: {
            $0.menuBarApplicationClient = .testValue
        }

        await store.send(.focusOnVoicePicked(true))
        await store.receive(\.delegate)
    }
}
