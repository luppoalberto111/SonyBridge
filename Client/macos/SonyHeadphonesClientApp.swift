//
//  SonyHeadphonesClientApp.swift
//  SwiftUI entry point: window, appearance and menu commands.
//

import SwiftUI

@main
struct SonyHeadphonesClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainScreenView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 560)
        .defaultPosition(.center)
        .commands {
            HeadphonesCommands()
        }
    }
}
