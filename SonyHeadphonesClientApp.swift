import ComposableArchitecture
import Foundation
import SwiftUI

@main struct SonyHeadphonesClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    /// Xcode's preview host launches the app entry point. The one-time
    /// launch-at-login prompt cannot be presented in that host and crashes AppKit.
    private var isRunningInPreview: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }

    var body: some Scene {
        WindowGroup {
            MainScreenView(store: store.scope(state: \.mainScreen, action: \.mainScreen))
                .task {
                    if !isRunningInPreview {
                        store.send(.launchAtLogin(.task))
                    }
                }
                .alert(
                    String(
                        localized: "LaunchAtLoginAlert.title",
                        defaultValue: "Launch at login?"
                    ),
                    isPresented: Binding(
                        get: { !isRunningInPreview && store.launchAtLogin.promptVisible },
                        set: { _ in }
                    )
                ) {
                    Button(String(
                        localized: "LaunchAtLoginAlert.allow",
                        defaultValue: "Allow"
                    )) {
                        store.send(.launchAtLogin(.allowTapped))
                    }
                    Button(
                        String(
                            localized: "LaunchAtLoginAlert.deny",
                            defaultValue: "Not Now"
                        ),
                        role: .cancel
                    ) {
                        store.send(.launchAtLogin(.denyTapped))
                    }
                } message: {
                    Text(String(
                        localized: "LaunchAtLoginAlert.message",
                        // swiftlint:disable:next line_length
                        defaultValue: "SonyHeadphonesClient can start automatically when you log in. You can change this anytime in System Settings."
                    ))
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 560)
        .defaultPosition(.center)
        .commands {
            HeadphonesCommands(
                connectClosure: { store.send(.mainScreen(.disconnected(.connectButtonTapped))) },
                disconnectClosure: { store.send(.mainScreen(.connected(.disconnectButtonTapped))) }
            )
        }
    }
}
