import Bridge

// The bridge funnels every command through its own internal serial queue and
// only ever touches its C++ core from there, so sharing it with the actor is
// sound. It cannot be marked Sendable in Obj-C, hence the unchecked conformance.
extension HeadphonesBridge: @unchecked @retroactive Sendable {}
