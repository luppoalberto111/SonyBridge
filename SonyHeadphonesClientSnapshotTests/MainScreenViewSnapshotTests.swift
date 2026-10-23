import Client
import ComposableArchitecture
import Foundation
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct MainScreenViewSnapshotTests {
    @Test func disconnected() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                MainScreenView(
                    store: SnapshotFixtures.mainScreenStore(
                        state: .disconnected(DisconnectedReducer.State())
                    )
                )
            ),
            as: .image(precision: 0.95, size: CGSize(width: 380, height: 560))
        )
    }

    @Test func connected() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                MainScreenView(
                    store: SnapshotFixtures.mainScreenStore(
                        state: .connected(
                            ConnectedReducer.State(
                                headphones: SnapshotFixtures.singleBatteryHeadphones()
                            )
                        )
                    )
                )
            ),
            as: .image(precision: 0.95, size: CGSize(width: 380, height: 900))
        )
    }
}
