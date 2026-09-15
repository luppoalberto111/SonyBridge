import AppKit
import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct DeviceHeroViewSnapshotTests {
    @Test func singleBattery() {
        assertSnapshot(
            of: DeviceHeroView(
                store: SnapshotFixtures.deviceHeroStore(
                    headphones: SnapshotFixtures.singleBatteryHeadphones()
                )
            ),
            as: .image(layout: .fixed(width: 380, height: 420))
        )
    }

    @Test func dualBattery() {
        assertSnapshot(
            of: DeviceHeroView(
                store: SnapshotFixtures.deviceHeroStore(
                    headphones: SnapshotFixtures.dualBatteryHeadphones()
                )
            ),
            as: .image(layout: .fixed(width: 380, height: 420))
        )
    }
}
