import SwiftUI

struct HeadphonesCommands: Commands {
    var connectClosure: () -> Void = {}
    var disconnectClosure: () -> Void = {}

    var body: some Commands {
        CommandMenu("Headphones") {
            Button("Connect to Headphones", action: connectClosure)
                .keyboardShortcut("k", modifiers: .command)
            Button("Disconnect", action: disconnectClosure)
                .keyboardShortcut("d", modifiers: [.command, .shift])
        }
    }
}
