import ComposableArchitecture
@testable import SonyHeadphonesClient
import Testing

@Suite(.serialized)
@MainActor struct LaunchAtLoginFeatureTests {
    private func initialState(promptResolved: Bool) -> LaunchAtLoginFeature.State {
        var state = LaunchAtLoginFeature.State()
        state.$promptResolved.withLock { $0 = promptResolved }
        return state
    }

    @Test func taskShowsPromptWhenUnresolved() async {
        let store = TestStore(initialState: initialState(promptResolved: false)) {
            LaunchAtLoginFeature()
        } withDependencies: {
            $0.launchAtLoginClient.isEnabled = { false }
        }
        store.exhaustivity = .off

        await store.send(.task)
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.promptVisible == true)
        #expect(store.state.launchAtLoginEnabled == false)
    }

    @Test func taskSkipsPromptWhenResolved() async {
        let store = TestStore(initialState: initialState(promptResolved: true)) {
            LaunchAtLoginFeature()
        } withDependencies: {
            $0.launchAtLoginClient.isEnabled = { true }
        }
        store.exhaustivity = .off

        await store.send(.task)
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.promptVisible == false)
        #expect(store.state.launchAtLoginEnabled == true)
    }

    @Test func allowRegistersAndMarksResolved() async {
        var requested = false
        let store = TestStore(initialState: initialState(promptResolved: false)) {
            LaunchAtLoginFeature()
        } withDependencies: {
            $0.launchAtLoginClient.setEnabled = {
                requested = $0
                return true
            }
        }
        store.exhaustivity = .off

        await store.send(.allowTapped)
        await store.finish()
        await store.skipReceivedActions()

        #expect(requested == true)
        #expect(store.state.promptVisible == false)
        #expect(store.state.launchAtLoginEnabled == true)
        #expect(LaunchAtLoginFeature.State().promptResolved == true)
    }

    @Test func denyMarksResolvedWithoutRegistering() async {
        var requested = false
        let store = TestStore(initialState: initialState(promptResolved: false)) {
            LaunchAtLoginFeature()
        } withDependencies: {
            $0.launchAtLoginClient.setEnabled = {
                requested = $0
                return true
            }
        }
        store.exhaustivity = .off

        await store.send(.denyTapped)
        await store.finish()

        #expect(requested == false)
        #expect(store.state.promptVisible == false)
        #expect(LaunchAtLoginFeature.State().promptResolved == true)
    }

    @Test func failedRegistrationKeepsDisabledState() async {
        let store = TestStore(initialState: initialState(promptResolved: false)) {
            LaunchAtLoginFeature()
        } withDependencies: {
            $0.launchAtLoginClient.setEnabled = { _ in false }
        }
        store.exhaustivity = .off

        await store.send(.allowTapped)
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.promptVisible == false)
        #expect(store.state.launchAtLoginEnabled == false)
    }
}
