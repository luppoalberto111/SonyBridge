//
//  AppDelegate.swift
//  SonyHeadphonesClient
//
//  Programmatic app entry point (no storyboard, no main nib): builds the main
//  menu, creates the window and hosts the SwiftUI interface in it.
//

import Cocoa
import SwiftUI

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?

    /// Retained for the lifetime of the app (`NSApplication.delegate` is weak).
    /// Set once on the main thread before the run loop starts.
    nonisolated(unsafe) private static var shared: AppDelegate?

    /// Custom entry point: with no storyboard or nib nothing would ever
    /// instantiate the delegate, so create it and attach it before running.
    static func main() {
        let delegate = AppDelegate()
        shared = delegate
        NSApplication.shared.delegate = delegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SonyHeadphonesClient"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentMinSize = NSSize(width: 360, height: 500)
        window.contentMaxSize = NSSize(width: 560, height: 900)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentViewController = NSHostingController(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
        self.window = window
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

    // MARK: - Main menu (replaces the storyboard's Main Menu scene)

    private func buildMainMenu() {
        let app = NSApplication.shared
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SonyHeadphonesClient"
        let mainMenu = NSMenu()

        // Application menu.
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Preferences…", action: nil, keyEquivalent: ",")
        appMenu.addItem(.separator())
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        app.servicesMenu = servicesMenu
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // Window menu.
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        app.windowsMenu = windowMenu

        app.mainMenu = mainMenu
    }
}
