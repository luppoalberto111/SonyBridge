import Cocoa
import Dependencies

// MARK: - MenuBarApplicationClient

struct MenuBarApplicationClient: Sendable {
    var activateApp: @Sendable @MainActor () -> Void
    var terminateApp: @Sendable @MainActor () -> Void
}

// MARK: DependencyKey

extension MenuBarApplicationClient: DependencyKey {
    static var liveValue: Self {
        Self(
            activateApp: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first(where: \.canBecomeMain) {
                    window.makeKeyAndOrderFront(nil)
                }
            },
            terminateApp: {
                NSApplication.shared.terminate(nil)
            }
        )
    }

    static var testValue: Self {
        Self(
            activateApp: {},
            terminateApp: {}
        )
    }
}

extension DependencyValues {
    var menuBarApplicationClient: MenuBarApplicationClient {
        get { self[MenuBarApplicationClient.self] }
        set { self[MenuBarApplicationClient.self] = newValue }
    }
}
