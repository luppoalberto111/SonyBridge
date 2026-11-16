import ComposableArchitecture
import SwiftUI

// MARK: - EqualizerReducer

@Reducer struct EqualizerReducer {
    @ObservableState struct State: Equatable {
        @Shared
        var uiState: HeadphonesUIState
    }

    enum Action {
        case setEqualizer(Int)
        case setBand(Int, Int)
        case setClearBass(Int)
        case delegate(Delegate)
    }

    enum Delegate {
        case setEqualizer(Int)
        case setBand(Int, Int)
        case setClearBass(Int)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case let .setEqualizer(preset):
                    return .send(.delegate(.setEqualizer(preset)))

                case let .setBand(index, value):
                    guard state.uiState.eqBands.indices.contains(index) else { return .none }
                    return .send(.delegate(.setBand(index, value)))

                case let .setClearBass(value):
                    return .send(.delegate(.setClearBass(value)))

                case .delegate:
                    return .none
            }
        }
    }
}

// MARK: - EqualizerView

struct EqualizerView: View {
    let store: StoreOf<EqualizerReducer>

    /// Frequency labels of the ten-band layout (WH-1000XM6).
    ///
    /// Its bands are raw device steps without a known dB mapping, so they are shown unsigned.
    private static let tenBandLabels = [
        "31",
        "63",
        "125",
        "250",
        "500",
        "1k",
        "2k",
        "4k",
        "8k",
        "16k"
    ]

    /// The presets this device understands.
    ///
    /// On the ten-band layout only Off and Custom have confirmed codes - the other preset bytes
    /// are unnamed there, and the standard codes don't apply.
    private var presets: [EqPreset] {
        store.uiState.tenBandEqualizer ? [.off, .manual] : EqPreset.allCases
    }

    /// The band rows to show: label and index into ``HeadphonesUIState/eqBands``.
    private var bandRows: [(label: String, index: Int)] {
        if store.uiState.tenBandEqualizer {
            return Self.tenBandLabels.enumerated()
                .prefix(store.uiState.eqBands.count)
                .map { (label: $0.element, index: $0.offset) }
        }
        return EqBand.allCases.map { (label: $0.label, index: $0.rawValue) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EqualizerView.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.foreground)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(presets, content: eqChip)
            }
            if store.uiState.eqPreset == EqPreset.manual.rawValue {
                Divider().background(Color.cardHi)
                ForEach(bandRows, id: \.index) { row in
                    eqBandRow(
                        row.label,
                        value: Binding(
                            get: { Double(store.uiState.eqBands[row.index]) },
                            set: { store.send(.setBand(row.index, Int($0.rounded()))) }
                        ),
                        display: store.uiState.eqBands[row.index],
                        raw: store.uiState.tenBandEqualizer
                    )
                }
                if !store.uiState.tenBandEqualizer {
                    eqBandRow(
                        String(localized: "EqualizerView.clearBass", defaultValue: "Bass"),
                        value: Binding(
                            get: { Double(store.uiState.clearBass) },
                            set: { store.send(.setClearBass(Int($0.rounded()))) }
                        ),
                        display: store.uiState.clearBass,
                        accent: true
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eqBandRow(
        _ label: String,
        value: Binding<Double>,
        display: Int,
        accent: Bool = false,
        raw: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accent ? Color(.highlight) : Color(.foregroundSecondary))
                .frame(width: 34, alignment: .leading)
            Slider(value: value, in: raw ? 0 ... 12 : -10 ... 10, step: 1)
                .accentColor(Color(.accent))
            Text(raw ? "\(display)" : "\(display > 0 ? "+" : "")\(display)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.foreground)
                .frame(width: 26, alignment: .trailing)
        }
    }

    private func eqChip(_ preset: EqPreset) -> some View {
        let selected = store.uiState.eqPreset == preset.rawValue
        return Button(action: { store.send(.setEqualizer(preset.rawValue)) }) {
            Text(preset.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selected ? .white : Color(.foregroundSecondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Color.accent : .cardHi)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(store.uiState.eqPresetLoading)
    }
}

#Preview {
    EqualizerView(
        store: Store(
            initialState: EqualizerReducer.State(
                uiState: Shared(
                    value: HeadphonesUIState(
                        eqPreset: EqPreset.excited.rawValue,
                        eqBands: [0, 0, 0, 0, 0],
                        clearBass: 0
                    )
                )
            )
        ) {
            EqualizerReducer()
        }
    )
}

#Preview {
    EqualizerView(
        store: Store(
            initialState: EqualizerReducer.State(
                uiState: Shared(
                    value: HeadphonesUIState(
                        eqPreset: EqPreset.manual.rawValue,
                        eqBands: [2, -1, 0, 3, -2],
                        clearBass: 5
                    )
                )
            )
        ) {
            EqualizerReducer()
        }
    )
}
