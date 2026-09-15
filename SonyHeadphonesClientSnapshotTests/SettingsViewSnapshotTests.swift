import AppKit
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
            of: SettingsView(store: SnapshotFixtures.settingsStore()),
            as: .image(layout: .fixed(width: 380, height: 260))
        )
    }
}
