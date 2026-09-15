import AppKit
import Client
import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct ConnectedViewSnapshotTests {
    @Test func fullyFeaturedHeadphones() {
        assertSnapshot(
            of: ConnectedView(
                store: SnapshotFixtures.connectedStore(
                    headphones: SnapshotFixtures.singleBatteryHeadphones()
                )
            ),
            as: .image(layout: .fixed(width: 380, height: 900))
        )
    }

    @Test func minimalHeadphones() {
        var headphones = HeadphonesState()
        headphones.connected = true
        headphones.deviceName = "WH-CH720N"

        assertSnapshot(
            of: ConnectedView(store: SnapshotFixtures.connectedStore(headphones: headphones)),
            as: .image(layout: .fixed(width: 380, height: 900))
        )
    }
}
