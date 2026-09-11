//
//  AppDelegate.swift
//  SonyHeadphonesClient
//

import Cocoa

@objc(AppDelegate)
final class AppDelegate: NSObject, NSApplicationDelegate {

    weak var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSApplication.shared.windows.first
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return false
        } else {
            window?.makeKeyAndOrderFront(self)
            return true
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
    }
}
