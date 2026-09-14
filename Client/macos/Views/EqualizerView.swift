import SwiftUI

struct EqualizerView: View {
    struct Model {
        let eqPreset: Int
        let eqBands: [Int]
        let clearBass: Int
    }

    let model: Model

    var setEqualizer: (Int) -> Void = { _ in }
    var setBand: (Int, Int) -> Void = { _, _ in }
    var setClearBass: (Int) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EqualizerView.title")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(EqPreset.allCases, content: eqChip)
            }
            if model.eqPreset == EqPreset.manual.rawValue {
                Divider().background(Theme.cardHi)
                ForEach(EqBand.allCases) { band in
                    eqBandRow(band.label, value: Binding(
                        get: { Double(model.eqBands[band.rawValue]) },
                        set: { setBand(band.rawValue, Int($0.rounded())) }
                    ), display: model.eqBands[band.rawValue])
                }
                eqBandRow(String(localized: "EqualizerView.clearBass", defaultValue: "Bass"), value: Binding(
                    get: { Double(model.clearBass) },
                    set: { setClearBass(Int($0.rounded())) }
                ), display: model.clearBass, accent: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eqBandRow(_ label: String, value: Binding<Double>, display: Int, accent: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accent ? Theme.accent : Theme.secondary)
                .frame(width: 34, alignment: .leading)
            Slider(value: value, in: -10...10, step: 1).accentColor(Theme.accent)
            Text("\(display > 0 ? "+" : "")\(display)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 26, alignment: .trailing)
        }
    }

    private func eqChip(_ preset: EqPreset) -> some View {
        let selected = model.eqPreset == preset.rawValue
        return Button(action: { setEqualizer(preset.rawValue) }) {
            Text(preset.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selected ? .white : Theme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Theme.accent : Theme.cardHi)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EqualizerView(
        model: .init(
            eqPreset: EqPreset.excited.rawValue,
            eqBands: [0, 0, 0, 0, 0],
            clearBass: 0
        )
    )
}

#Preview {
    EqualizerView(
        model: .init(
            eqPreset: EqPreset.manual.rawValue,
            eqBands: [2, -1, 0, 3, -2],
            clearBass: 5
        )
    )
}
