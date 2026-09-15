import AppKit
import Client
import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct MainScreenViewSnapshotTests {
    @Test func disconnected() {
        assertSnapshot(
            of: MainScreenView(
                store: SnapshotFixtures.mainScreenStore(
                    state: .disconnected(DisconnectedReducer.State())
                )
            ),
            as: .image(layout: .fixed(width: 380, height: 560))
        )
    }

    @Test func connected() {
        assertSnapshot(
            of: MainScreenView(
                store: SnapshotFixtures.mainScreenStore(
                    state: .connected(
                        ConnectedReducer.State(
                            headphones: SnapshotFixtures.singleBatteryHeadphones()
                        )
                    )
                )
            ),
            as: .image(layout: .fixed(width: 380, height: 900))
        )
    }
}
