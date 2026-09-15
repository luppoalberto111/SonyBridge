import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

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
            as: .image(size: CGSize(width: 380, height: 420))
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
            as: .image(size: CGSize(width: 380, height: 420))
        )
    }
}
