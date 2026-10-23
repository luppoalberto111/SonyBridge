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
