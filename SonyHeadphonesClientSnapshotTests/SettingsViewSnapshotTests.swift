import Client
import ComposableArchitecture
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct SettingsViewSnapshotTests {
    @Test func allCapabilitiesAvailable() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                SettingsView(store: SnapshotFixtures.settingsStore())
            ),
            as: .image(size: CGSize(width: 380, height: 260))
        )
    }
}
