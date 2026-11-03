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
                AmbientView(
                    store: SnapshotFixtures.ambientStore(
                        mode: .noiseCanceling,
                        focusOnVoiceLoading: false
                    )
                )
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 320)
            )
        )
    }

    @Test func ambientSoundWithFocusOnVoice() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                AmbientView(
                    store: SnapshotFixtures.ambientStore(
                        mode: .ambientSound,
                        focusOnVoiceAvailable: true,
                        focusOnVoiceLoading: false
                    )
                )
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 320)
            )
        )
    }

    @Test func ambientSoundWithFocusOnVoiceLoading() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                AmbientView(
                    store: SnapshotFixtures.ambientStore(
                        mode: .ambientSound,
                        focusOnVoiceAvailable: true,
                        focusOnVoiceLoading: true
                    )
                )
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 320)
            )
        )
    }

    @Test func off() {
        assertSnapshot(
            of: SnapshotFixtures.hostingController(
                AmbientView(store: SnapshotFixtures.ambientStore(
                    mode: .off,
                    focusOnVoiceLoading: false
                ))
            ),
            as: .image(
                precision: 0.95,
                perceptualPrecision: 0.95,
                size: CGSize(width: 380, height: 320)
            )
        )
    }
}
