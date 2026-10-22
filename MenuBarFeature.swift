import Bridge
import Cocoa
import ComposableArchitecture
import Dependencies

// MARK: - Shared isConnected

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
    static var isConnected: Self {
        Self[.inMemory("isConnected"), default: false]
    }
}

extension SharedReaderKey where Self == InMemoryKey<SHCAmbientMode>.Default {
    static var ambientMode: Self {
        Self[.inMemory("ambientMode"), default: .off]
    }
}

extension SharedReaderKey where Self == InMemoryKey<Int>.Default {
    static var ambientLevel: Self {
        Self[.inMemory("ambientLevel"), default: 10]
    }

    static var maxAmbientLevel: Self {
        Self[.inMemory("maxAmbientLevel"), default: 20]
    }

    static var batteryLevel: Self {
        Self[.inMemory("batteryLevel"), default: -1]
    }
}

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
    static var focusOnVoice: Self {
        Self[.inMemory("focusOnVoice"), default: false]
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
        @Shared(.ambientMode)
        var ambientMode: SHCAmbientMode
        @Shared(.ambientLevel)
        var ambientLevel: Int
        @Shared(.maxAmbientLevel)
        var maxAmbientLevel: Int
        @Shared(.focusOnVoice)
        var focusOnVoice: Bool
        @Shared(.batteryLevel)
        var batteryLevel: Int
    }

    enum Action {
        case openTapped
        case connectTapped
        case disconnectTapped
        case ambientModeTapped(SHCAmbientMode)
        case ambientLevelPicked(Int)
        case focusOnVoicePicked(Bool)
        case quitTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case connectRequested
        case disconnectRequested
        case ambientModeSelected(SHCAmbientMode)
        case ambientLevelSelected(Int)
        case focusOnVoiceSelected(Bool)
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

                case let .ambientModeTapped(mode):
                    return .send(.delegate(.ambientModeSelected(mode)))

                case let .ambientLevelPicked(level):
                    return .send(.delegate(.ambientLevelSelected(level)))

                case let .focusOnVoicePicked(focusOn):
                    return .send(.delegate(.focusOnVoiceSelected(focusOn)))

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

// MARK: - StatusMenuController

/// Formats the top menu row, e.g. "Battery: 80%". Unknown levels render as "--".
func batteryMenuTitle(level: Int) -> String {
    level >= 0 ? "Battery: \(level)%" : "Battery: --"
}

// MARK: - StatusMenuController

/// AppKit glue: owns the `NSStatusItem` and forwards menu taps to the store.
///
/// Item visibility is refreshed in `menuWillOpen(_:)`: Connect only appears
/// while disconnected; Battery, Ambient Sound and Disconnect only appear
/// while connected.
@MainActor final class StatusMenuController: NSObject, NSMenuDelegate {
    private let store: StoreOf<MenuBarFeature>
    private let statusItem: NSStatusItem
    private let batteryItem: NSMenuItem
    private let connectItem: NSMenuItem
    private let disconnectItem: NSMenuItem
    private let ambientItem: NSMenuItem
    private let ambientModeItems: [NSMenuItem]
    private let ambientModes: [SHCAmbientMode] = [.off, .ambientSound, .noiseCanceling]
    private let ambientLevelItem: NSMenuItem
    private let ambientLevelSlider: NSSlider
    private let focusOnVoiceItem: NSMenuItem
    private var lastSentAmbientLevel: Int?

    init(store: StoreOf<MenuBarFeature>) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.batteryItem = NSMenuItem(
            title: "Battery: --",
            action: nil,
            keyEquivalent: ""
        )
        self.connectItem = NSMenuItem(
            title: "Connect",
            action: #selector(handleConnect),
            keyEquivalent: ""
        )
        self.disconnectItem = NSMenuItem(
            title: "Disconnect",
            action: #selector(handleDisconnect),
            keyEquivalent: ""
        )
        self.ambientItem = NSMenuItem(
            title: "Ambient Sound",
            action: nil,
            keyEquivalent: ""
        )
        self.ambientModeItems = [
            NSMenuItem(title: "Off", action: #selector(handleAmbientMode(_:)), keyEquivalent: ""),
            NSMenuItem(
                title: "Ambient Sound",
                action: #selector(handleAmbientMode(_:)),
                keyEquivalent: ""
            ),
            NSMenuItem(
                title: "Noise Canceling",
                action: #selector(handleAmbientMode(_:)),
                keyEquivalent: ""
            ),
        ]
        self.ambientLevelItem = NSMenuItem()
        self.ambientLevelSlider = NSSlider()
        self.focusOnVoiceItem = NSMenuItem(
            title: "Focus on Voice",
            action: #selector(handleFocusOnVoice),
            keyEquivalent: ""
        )
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "headphones",
                accessibilityDescription: "My App"
            )
        }

        let ambientMenu = NSMenu()
        for (index, item) in ambientModeItems.enumerated() {
            item.target = self
            item.tag = index
            ambientMenu.addItem(item)
        }
        ambientItem.submenu = ambientMenu

        let sliderContainer = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 28))
        let levelLabel = NSTextField(labelWithString: "Level")
        levelLabel.frame = NSRect(x: 16, y: 6, width: 46, height: 16)
        levelLabel.font = .systemFont(ofSize: 12)
        levelLabel.textColor = .secondaryLabelColor
        sliderContainer.addSubview(levelLabel)
        ambientLevelSlider.frame = NSRect(x: 70, y: 3, width: 134, height: 22)
        ambientLevelSlider.minValue = 1
        ambientLevelSlider.maxValue = 20
        ambientLevelSlider.target = self
        ambientLevelSlider.action = #selector(handleAmbientLevel(_:))
        sliderContainer.addSubview(ambientLevelSlider)
        ambientLevelItem.view = sliderContainer
        focusOnVoiceItem.target = self

        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open", action: #selector(handleOpen), keyEquivalent: "O")
        openItem.target = self
        menu.addItem(batteryItem)
        menu.addItem(openItem)
        connectItem.target = self
        menu.addItem(connectItem)
        menu.addItem(ambientItem)
        menu.addItem(ambientLevelItem)
        menu.addItem(focusOnVoiceItem)
        menu.addItem(NSMenuItem.separator())
        disconnectItem.target = self
        menu.addItem(disconnectItem)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        let connected = store.state.isConnected
        let ambientSelected = connected && store.state.ambientMode == .ambientSound
        batteryItem.isHidden = !connected
        batteryItem.title = batteryMenuTitle(level: store.state.batteryLevel)
        connectItem.isHidden = connected
        disconnectItem.isHidden = !connected
        ambientItem.isHidden = !connected
        ambientLevelItem.isHidden = !ambientSelected
        focusOnVoiceItem.isHidden = !ambientSelected
        let currentMode = store.state.ambientMode
        for (index, item) in ambientModeItems.enumerated() {
            item.state = ambientModes[index] == currentMode ? .on : .off
        }
        ambientLevelSlider.maxValue = Double(max(store.state.maxAmbientLevel, 1))
        let sliderLevel = min(
            max(store.state.ambientLevel, 1),
            store.state.maxAmbientLevel
        )
        ambientLevelSlider.integerValue = sliderLevel
        lastSentAmbientLevel = sliderLevel
        focusOnVoiceItem.state = store.state.focusOnVoice ? .on : .off
    }

    @objc private func handleOpen() {
        store.send(.openTapped)
    }

    @objc private func handleConnect() {
        store.send(.connectTapped)
    }

    @objc private func handleDisconnect() {
        store.send(.disconnectTapped)
    }

    @objc private func handleAmbientMode(_ sender: NSMenuItem) {
        guard ambientModes.indices.contains(sender.tag) else { return }
        store.send(.ambientModeTapped(ambientModes[sender.tag]))
    }

    @objc private func handleAmbientLevel(_ sender: NSSlider) {
        // The slider fires continuously while dragging, often repeating the
        // same integer. Only forward actual changes so each tick doesn't
        // trigger its own Bluetooth round-trip and stall the menu.
        let level = sender.integerValue
        guard level != lastSentAmbientLevel else { return }
        lastSentAmbientLevel = level
        store.send(.ambientLevelPicked(level))
    }

    @objc private func handleFocusOnVoice() {
        store.send(.focusOnVoicePicked(!store.state.focusOnVoice))
    }

    @objc private func handleQuit() {
        store.send(.quitTapped)
    }
}
