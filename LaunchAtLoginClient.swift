import Dependencies
import ServiceManagement

// MARK: - LaunchAtLoginClient

struct LaunchAtLoginClient: Sendable {
    /// Whether the app is currently registered to launch at login.
    var isEnabled: @Sendable @MainActor () -> Bool
    /// Registers/unregisters the login item and returns the resulting status.
    /// Failures resolve to the actual current status instead of throwing.
    var setEnabled: @Sendable @MainActor (Bool) -> Bool
}

// MARK: DependencyKey

extension LaunchAtLoginClient: DependencyKey {
    static var liveValue: Self {
        Self(
            isEnabled: {
                SMAppService.mainApp.status == .enabled
            },
            setEnabled: { enabled in
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    // Best effort: fall through to reporting the actual status.
                }
                return SMAppService.mainApp.status == .enabled
            }
        )
    }

    static var testValue: Self {
        Self(
            isEnabled: { false },
            setEnabled: { _ in false }
        )
    }
}

extension DependencyValues {
    var launchAtLoginClient: LaunchAtLoginClient {
        get { self[LaunchAtLoginClient.self] }
        set { self[LaunchAtLoginClient.self] = newValue }
    }
}
