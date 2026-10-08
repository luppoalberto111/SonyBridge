import ComposableArchitecture
import SwiftUI

@main struct SonyHeadphonesClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        appDelegate.configure(statusMenuStore: store.scope(state: \.menuBar, action: \.menuBar))
    }

    var body: some Scene {
        WindowGroup {
            MainScreenView(store: store.scope(state: \.mainScreen, action: \.mainScreen))
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
