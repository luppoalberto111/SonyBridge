import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct EqualizerViewSnapshotTests {
    @Test func presetSelected() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                EqualizerView(store: SnapshotFixtures.equalizerStore(preset: .excited))
            ),
            as: .image(size: CGSize(width: 380, height: 420))
        )
    }

    @Test func manualPresetShowsBandSliders() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                EqualizerView(store: SnapshotFixtures.equalizerStore(preset: .manual))
            ),
            as: .image(size: CGSize(width: 380, height: 420))
        )
    }
}
