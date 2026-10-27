import Cocoa
import Dependencies

// MARK: - MenuBarApplicationClient

public struct MenuBarApplicationClient: Sendable {
    public var terminateApp: @Sendable @MainActor () -> Void
}

// MARK: DependencyKey

extension MenuBarApplicationClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            terminateApp: {
                NSApplication.shared.terminate(nil)
            }
        )
    }

    public static var testValue: Self {
        Self(
            terminateApp: {}
        )
    }
}

extension DependencyValues {
    public var menuBarApplicationClient: MenuBarApplicationClient {
        get { self[MenuBarApplicationClient.self] }
        set { self[MenuBarApplicationClient.self] = newValue }
    }
}
