import AppKit
import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct EqualizerViewSnapshotTests {
    @Test func presetSelected() {
        assertSnapshot(
            of: EqualizerView(store: SnapshotFixtures.equalizerStore(preset: .excited)),
            as: .image(layout: .fixed(width: 380, height: 420))
        )
    }

    @Test func manualPresetShowsBandSliders() {
        assertSnapshot(
            of: EqualizerView(store: SnapshotFixtures.equalizerStore(preset: .manual)),
            as: .image(layout: .fixed(width: 380, height: 420))
        )
    }
}
