import Client
import ComposableArchitecture
import Foundation
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct DseeViewSnapshotTests {
    @Test func off() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DseeView(store: SnapshotFixtures.dseeStore())
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 120)
            )
        )
    }

    @Test func loading() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                DseeView(
                    store: SnapshotFixtures.dseeStore(),
                    dseeLoading: true
                )
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 120)
            )
        )
    }
}
