import Bridge
import Client
import ComposableArchitecture
import SnapshotTesting
@testable import SonyHeadphonesClient
import SwiftUI
import Testing

@MainActor struct AmbientViewSnapshotTests {
    @Test func noiseCanceling() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                AmbientView(store: SnapshotFixtures.ambientStore(mode: .noiseCanceling))
            ),
            as: .image(size: CGSize(width: 380, height: 320))
        )
    }

    @Test func ambientSoundWithFocusOnVoice() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                AmbientView(
                    store: SnapshotFixtures.ambientStore(
                        mode: .ambientSound,
                        focusOnVoiceAvailable: true
                    )
                )
            ),
            as: .image(size: CGSize(width: 380, height: 320))
        )
    }

    @Test func off() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                AmbientView(store: SnapshotFixtures.ambientStore(mode: .off))
            ),
            as: .image(size: CGSize(width: 380, height: 320))
        )
    }
}
