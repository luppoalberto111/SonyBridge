import AppKit
import Bridge
import Client
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import SonyHeadphonesClient

@MainActor struct AmbientViewSnapshotTests {
    @Test func noiseCanceling() {
        assertSnapshot(
            of: AmbientView(store: SnapshotFixtures.ambientStore(mode: .noiseCanceling)),
            as: .image(layout: .fixed(width: 380, height: 320))
        )
    }

    @Test func ambientSoundWithFocusOnVoice() {
        assertSnapshot(
            of: AmbientView(
                store: SnapshotFixtures.ambientStore(
                    mode: .ambientSound,
                    focusOnVoiceAvailable: true
                )
            ),
            as: .image(layout: .fixed(width: 380, height: 320))
        )
    }

    @Test func off() {
        assertSnapshot(
            of: AmbientView(store: SnapshotFixtures.ambientStore(mode: .off)),
            as: .image(layout: .fixed(width: 380, height: 320))
        )
    }
}
