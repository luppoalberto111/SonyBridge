import Bridge

// The bridge funnels every command through its own internal serial queue and
// only ever touches its C++ core from there, so sharing it with the actor is
// sound. It cannot be marked Sendable in Obj-C, hence the unchecked conformance.
/// Adopts the Objective-C bridge in Swift's concurrency model.
///
/// The unchecked conformance is justified by the bridge's own synchronization: every command runs on
/// its serial dispatch queue, and the read paths are serialized by the C++ connector mutex, so the
/// actor can share one instance without data races.
extension HeadphonesBridge: @unchecked @retroactive Sendable {}
