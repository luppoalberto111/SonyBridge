import Client
import ComposableArchitecture
import SwiftUI

// MARK: - EqualizerReducer

@Reducer struct EqualizerReducer {
    @ObservableState struct State: Equatable {
        var eqPreset = 0
        var eqBands = [0, 0, 0, 0, 0]
        var clearBass = 0

        mutating func sync(from headphones: HeadphonesState) {
            eqPreset = headphones.eqPreset
            eqBands = headphones.eqBands
            clearBass = headphones.clearBass
        }
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
                    state.eqPreset = preset
                    return .send(.delegate(.setEqualizer(preset)))

                case let .setBand(index, value):
                    guard state.eqBands.indices.contains(index) else { return .none }
                    state.eqBands[index] = value
                    state.eqPreset = 0xA0
                    return .send(.delegate(.setBand(index, value)))

                case let .setClearBass(value):
                    state.clearBass = value
                    state.eqPreset = 0xA0
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EqualizerView.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(.foreground))
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(EqPreset.allCases, content: eqChip)
            }
            if store.eqPreset == EqPreset.manual.rawValue {
                Divider().background(Color(.cardHi))
                ForEach(EqBand.allCases) { band in
                    eqBandRow(
                        band.label,
                        value: Binding(
                            get: { Double(store.eqBands[band.rawValue]) },
                            set: { store.send(.setBand(band.rawValue, Int($0.rounded()))) }
                        ),
                        display: store.eqBands[band.rawValue]
                    )
                }
                eqBandRow(
                    String(localized: "EqualizerView.clearBass", defaultValue: "Bass"),
                    value: Binding(
                        get: { Double(store.clearBass) },
                        set: { store.send(.setClearBass(Int($0.rounded()))) }
                    ),
                    display: store.clearBass,
                    accent: true
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.card))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eqBandRow(
        _ label: String,
        value: Binding<Double>,
        display: Int,
        accent: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accent ? Color(.accent) : Color(.secondary))
                .frame(width: 34, alignment: .leading)
            Slider(value: value, in: -10 ... 10, step: 1).accentColor(Color(.accent))
            Text("\(display > 0 ? "+" : "")\(display)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(.foreground))
                .frame(width: 26, alignment: .trailing)
        }
    }

    private func eqChip(_ preset: EqPreset) -> some View {
        let selected = store.eqPreset == preset.rawValue
        return Button(action: { store.send(.setEqualizer(preset.rawValue)) }) {
            Text(preset.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selected ? .white : Color(.secondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Color(.accent) : Color(.cardHi))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EqualizerView(
        store: Store(
            initialState: EqualizerReducer.State(
                eqPreset: EqPreset.excited.rawValue,
                eqBands: [0, 0, 0, 0, 0],
                clearBass: 0
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
                eqPreset: EqPreset.manual.rawValue,
                eqBands: [2, -1, 0, 3, -2],
                clearBass: 5
            )
        ) {
            EqualizerReducer()
        }
    )
}
