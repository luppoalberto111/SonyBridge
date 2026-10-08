import Cocoa
import ComposableArchitecture
import Dependencies

// MARK: - Shared isConnected

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
    static var isConnected: Self {
        Self[.inMemory("isConnected"), default: false]
    }
}

// MARK: - MenuBarFeature

/// Status-bar menu state machine. Every `NSMenuItem` forwards to an action;
/// connect/disconnect bubble up as delegate actions, while open/quit run
/// through `menuBarApplicationClient` so the reducer stays testable.
@Reducer struct MenuBarFeature {
    @ObservableState struct State: Equatable {
        @Shared(.isConnected)
        var isConnected: Bool
    }

    enum Action {
        case openTapped
        case connectTapped
        case disconnectTapped
        case quitTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case connectRequested
        case disconnectRequested
    }

    @Dependency(\.menuBarApplicationClient)
    var applicationClient

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
                case .openTapped:
                    return .run { _ in
                        await applicationClient.activateApp()
                    }

                case .connectTapped:
                    return .send(.delegate(.connectRequested))

                case .disconnectTapped:
                    return .send(.delegate(.disconnectRequested))

                case .quitTapped:
                    return .run { _ in
                        await applicationClient.terminateApp()
                    }

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - MenuBarApplicationClient

struct MenuBarApplicationClient: Sendable {
    var activateApp: @Sendable @MainActor () -> Void
    var terminateApp: @Sendable @MainActor () -> Void
}

// MARK: DependencyKey

extension MenuBarApplicationClient: DependencyKey {
    static var liveValue: Self {
        Self(
            activateApp: {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first(where: \.canBecomeMain) {
                    window.makeKeyAndOrderFront(nil)
                }
            },
            terminateApp: {
                NSApplication.shared.terminate(nil)
            }
        )
    }

    static var testValue: Self {
        Self(
            activateApp: {},
            terminateApp: {}
        )
    }
}

extension DependencyValues {
    var menuBarApplicationClient: MenuBarApplicationClient {
        get { self[MenuBarApplicationClient.self] }
        set { self[MenuBarApplicationClient.self] = newValue }
    }
}

// MARK: - StatusMenuController

/// AppKit glue: owns the `NSStatusItem` and forwards menu taps to the store.
///
/// The connect/disconnect title is refreshed in `menuWillOpen(_:)`
/// so it always reflects the latest `MenuBarFeature.State`.
@MainActor final class StatusMenuController: NSObject, NSMenuDelegate {
    private let store: StoreOf<MenuBarFeature>
    private let statusItem: NSStatusItem
    private let toggleConnectItem: NSMenuItem

    init(store: StoreOf<MenuBarFeature>) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.toggleConnectItem = NSMenuItem(
            title: "Connect",
            action: #selector(handleConnectToggle),
            keyEquivalent: ""
        )
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "headphones",
                accessibilityDescription: "My App"
            )
        }

        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open", action: #selector(handleOpen), keyEquivalent: "O")
        openItem.target = self
        menu.addItem(openItem)
        toggleConnectItem.target = self
        menu.addItem(toggleConnectItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        toggleConnectItem.title = store.state.isConnected ? "Disconnect" : "Connect"
    }

    @objc private func handleOpen() {
        store.send(.openTapped)
    }

    @objc private func handleConnectToggle() {
        store.send(store.state.isConnected ? .disconnectTapped : .connectTapped)
    }

    @objc private func handleQuit() {
        store.send(.quitTapped)
    }
}
