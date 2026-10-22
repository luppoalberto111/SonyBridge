import Dependencies
import DependenciesMacros

/// Registers ``HeadphonesClient`` as the app-wide `headphonesClient` dependency.
///
/// Tests and SwiftUI previews override it with a ``HeadphonesTestClient`` via
/// `withDependencies`, which is why the default value here is the test double rather than the live
/// client.
extension DependencyValues {
    /// The client reducers use to talk to the headset: a live ``HeadphonesClient`` in the app, a
    /// ``HeadphonesTestClient`` everywhere the dependency is overridden.
    @DependencyEntry(liveValue: HeadphonesClient())
    public var headphonesClient: any HeadphonesClientProtocol = HeadphonesTestClient()
}
