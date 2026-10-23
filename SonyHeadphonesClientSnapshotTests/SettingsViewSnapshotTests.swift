import Client
import ComposableArchitecture
import Foundation
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct SettingsViewSnapshotTests {
    @Test func allCapabilitiesAvailable() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                SettingsView(store: SnapshotFixtures.settingsStore())
            ),
            as: .image(precision: 0.99, size: CGSize(width: 380, height: 260))
        )
    }
}
