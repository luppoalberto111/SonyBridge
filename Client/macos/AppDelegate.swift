//
//  AppDelegate.swift
//  SonyHeadphonesClient
//
//  Application delegate companion to the SwiftUI App entry point.
//  Only handles Dock-icon reopen; window and menu come from SwiftUI.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Without activation SwiftUI leaves the WindowGroup window unordered
        // (e.g. launched from Terminal rather than Finder). Force the issue
        // so launch always presents the UI, like the old AppKit code did.
        NSApplication.shared.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return false
        }
        if let window = sender.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(self)
        }
        return true
    }
}
