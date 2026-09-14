//
//  SonyHeadphonesClientApp.swift
//  SwiftUI entry point: window, appearance and menu commands.
//

import SwiftUI

@main struct SonyHeadphonesClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    let viewModel = MainScreenViewModel()

    var body: some Scene {
        WindowGroup {
            MainScreenView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 560)
        .defaultPosition(.center)
        .commands {
            HeadphonesCommands(
                connectClosure: { viewModel.connect() },
                disconnectClosure: { viewModel.disconnect() }
            )
        }
    }
}
