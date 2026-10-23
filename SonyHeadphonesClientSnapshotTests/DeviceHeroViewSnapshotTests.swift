import ComposableArchitecture
import Foundation
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct DeviceHeroViewSnapshotTests {
    @Test func singleBattery() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DeviceHeroView(
                    store: SnapshotFixtures.deviceHeroStore(
                        headphones: SnapshotFixtures.singleBatteryHeadphones()
                    )
                )
            ),
            as: .image(precision: 0.95, size: CGSize(width: 380, height: 420))
        )
    }

    @Test func dualBattery() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DeviceHeroView(
                    store: SnapshotFixtures.deviceHeroStore(
                        headphones: SnapshotFixtures.dualBatteryHeadphones()
                    )
                )
            ),
            as: .image(precision: 0.95, size: CGSize(width: 380, height: 420))
        )
    }
}
