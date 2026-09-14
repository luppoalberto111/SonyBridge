//
//  SonyHeadphonesClientApp.swift
//  SwiftUI entry point: window, appearance and menu commands.
//

import ComposableArchitecture
import SwiftUI

@main struct SonyHeadphonesClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    let store = Store(initialState: MainScreenFeature.State(), reducer: MainScreenFeature.init)

    var body: some Scene {
        WindowGroup {
            MainScreenView(store: store)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 560)
        .defaultPosition(.center)
        .commands {
            HeadphonesCommands(
                connectClosure: { store.send(.disconnected(.connectButtonTapped)) },
                disconnectClosure: { store.send(.disconnectButtonTapped) }
            )
        }
    }
}
