import ComposableArchitecture
import SwiftUI

@main struct SonyHeadphonesClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    let store = Store(
        initialState: MainScreenFeature.State.disconnected(.init()),
        reducer: MainScreenFeature.init
    )

    init() {
        appDelegate.connectHandler = { [store] in
            store.send(.disconnected(.connectButtonTapped))
        }
    }

    var body: some Scene {
        WindowGroup {
            MainScreenView(store: store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 560)
        .defaultPosition(.center)
        .commands {
            HeadphonesCommands(
                connectClosure: { store.send(.disconnected(.connectButtonTapped)) },
                disconnectClosure: { store.send(.connected(.disconnectButtonTapped)) }
            )
        }
    }
}
