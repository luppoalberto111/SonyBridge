import Bridge
import ComposableArchitecture

// MARK: - Shared in-memory headphone state keys

//
// `@Shared(.inMemory(...))` values live in the current process only. The main
// app and the menu-bar executable are separate processes, so each one keeps
// its own copy; sharing this file keeps the key names and defaults identical
// in both targets.

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
    static var isConnected: Self {
        Self[.inMemory("isConnected"), default: false]
    }

    static var focusOnVoice: Self {
        Self[.inMemory("focusOnVoice"), default: false]
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
