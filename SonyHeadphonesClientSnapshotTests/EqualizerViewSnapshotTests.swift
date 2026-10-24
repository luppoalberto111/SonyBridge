import ComposableArchitecture
import Foundation
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct EqualizerViewSnapshotTests {
    @Test func presetSelected() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                EqualizerView(store: SnapshotFixtures.equalizerStore(preset: .excited))
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 420)
            )
        )
    }

    @Test func manualPresetShowsBandSliders() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                EqualizerView(store: SnapshotFixtures.equalizerStore(preset: .manual))
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 420)
            )
        )
    }
}
