import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    /// Forwarded to the `MainScreenFeature` store by `SonyHeadphonesClientApp`.
    var connectHandler: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "headphones",
                accessibilityDescription: "My App"
            )
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open", action: #selector(openApp), keyEquivalent: "O"))
        menu.addItem(NSMenuItem(title: "Connect", action: #selector(connectApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu

        NSApplication.shared.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if flag {
            return false
        }
        sender.windows.first(where: \.canBecomeMain)?.makeKeyAndOrderFront(self)

        return true
    }

    @objc @MainActor func openApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: \.canBecomeMain) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc @MainActor func connectApp() {
        connectHandler?()
    }
}
