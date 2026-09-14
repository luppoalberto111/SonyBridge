import SwiftUI

struct DseeView: View {
    struct Model {
        let dsee: Bool
    }

    let model: Model

    var setDsee: (Bool) -> Void = { _ in }

    var body: some View {
        Toggle(isOn: Binding(get: { model.dsee }, set: { setDsee($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DseeView.title").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("DseeView.subtitle").font(.system(size: 11)).foregroundColor(Theme.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    DseeView(model: .init(dsee: true))
}

#Preview {
    DseeView(model: .init(dsee: false))
}
