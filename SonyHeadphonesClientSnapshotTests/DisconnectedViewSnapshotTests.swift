import AppKit
import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct DisconnectedViewSnapshotTests {
    @Test func idle() {
        assertSnapshot(
            of: DisconnectedView(store: SnapshotFixtures.disconnectedStore()),
            as: .image(layout: .fixed(width: 380, height: 560))
        )
    }

    @Test func connecting() {
        assertSnapshot(
            of: DisconnectedView(store: SnapshotFixtures.connectingStore()),
            as: .image(layout: .fixed(width: 380, height: 560))
        )
    }

    @Test func deviceList() {
        assertSnapshot(
            of: DisconnectedView(store: SnapshotFixtures.deviceListStore()),
            as: .image(layout: .fixed(width: 380, height: 560))
        )
    }

    @Test func errorMessage() {
        assertSnapshot(
            of: DisconnectedView(store: SnapshotFixtures.errorStore()),
            as: .image(layout: .fixed(width: 380, height: 560))
        )
    }
}
