import ComposableArchitecture
import Foundation
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct DisconnectedViewSnapshotTests {
    @Test func idle() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DisconnectedView(store: SnapshotFixtures.disconnectedStore())
            ),
            as: .image(size: CGSize(width: 380, height: 560))
        )
    }

    @Test func connecting() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DisconnectedView(store: SnapshotFixtures.connectingStore())
            ),
            as: .image(size: CGSize(width: 380, height: 560))
        )
    }

    @Test func deviceList() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DisconnectedView(store: SnapshotFixtures.deviceListStore())
            ),
            as: .image(size: CGSize(width: 380, height: 560))
        )
    }

    @Test func errorMessage() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DisconnectedView(store: SnapshotFixtures.errorStore())
            ),
            as: .image(size: CGSize(width: 380, height: 560))
        )
    }
}
