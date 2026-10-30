import Cocoa
import ComposableArchitecture

/// NSApplicationDelegate for the standalone menu-bar executable.
///
/// Configures the status menu and keeps the app running as a menu-bar only
/// process (LSUIElement). It deliberately does not open the main app.
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate {
    private var statusMenuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = Store(initialState: MenuBarFeature.State(), reducer: MenuBarFeature.init)
        statusMenuController = StatusMenuController(store: store)
    }
}
