import Cocoa
import ComposableArchitecture

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusMenuController: StatusMenuController?

    /// Injects the menu-bar store. Called once from `SonyHeadphonesClientApp.init`.
    @MainActor func configure(statusMenuStore: StoreOf<MenuBarFeature>) {
        statusMenuController = StatusMenuController(store: statusMenuStore)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
}
