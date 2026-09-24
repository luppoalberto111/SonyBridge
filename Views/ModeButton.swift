import Bridge
import SwiftUI

// MARK: - ModeButton

struct ModeButton: View {
    let mode: SHCAmbientMode
    let isSelected: Bool

    var setMode: (SHCAmbientMode) -> Void = { _ in }

    var body: some View {
        Button(action: { setMode(mode) }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(.accent) : Color(.cardHi))
                        .frame(width: 58, height: 58)
                    Image(systemName: mode.symbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color(.secondary))
                }
                Text(mode.label)
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : Color(.secondary))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModeButton(mode: .noiseCanceling, isSelected: true)
}

extension SHCAmbientMode {
    var symbol: String {
        switch self {
            case .noiseCanceling: "speaker.slash.fill"
            case .ambientSound: "wind"
            case .off: "circle"
            @unknown default:
                ""
        }
    }

    var label: String {
        switch self {
            case .noiseCanceling: String(
                    localized: "AmbientMode.noiseCanceling",
                    defaultValue: "Noise\nCanceling"
                )
            case .ambientSound: String(
                    localized: "AmbientMode.ambientSound",
                    defaultValue: "Ambient\nSound"
                )
            case .off: String(localized: "AmbientMode.off", defaultValue: "Off")
            @unknown default:
                ""
        }
    }
}
