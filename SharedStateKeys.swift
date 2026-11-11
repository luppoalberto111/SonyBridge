import ComposableArchitecture

// MARK: - Shared in-memory headphone state key

//
// `@Shared(.inMemory(...))` values live in the current process only. The main
// app and the menu-bar executable are separate processes, so each one keeps
// its own copy; sharing this file keeps the key name and default identical in
// both targets.

extension SharedReaderKey where Self == InMemoryKey<HeadphonesUIState>.Default {
    static var headphonesState: Self {
        Self[.inMemory("headphonesState"), default: HeadphonesUIState()]
    }
}
