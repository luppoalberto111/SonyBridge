import SwiftUI

struct HeadphonesCommands: Commands {
    var body: some Commands {
        CommandMenu("Headphones") {
            Button("Connect to Headphones") {
                NotificationCenter.default.post(name: .connectHeadphones, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)
            Button("Disconnect") {
                NotificationCenter.default.post(name: .disconnectHeadphones, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
    }
}
