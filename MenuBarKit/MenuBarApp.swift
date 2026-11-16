import SwiftUI

/// Entry point for the standalone menu-bar executable.
///
/// `LSUIElement` keeps it out of the Dock, `Settings` gives SwiftUI a scene
/// without opening a window, and `MenuBarAppDelegate` owns the status item.
@main struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(MenuBarAppDelegate.self)
    var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
