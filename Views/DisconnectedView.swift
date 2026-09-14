import SwiftUI

struct DisconnectedView: View {
    let connecting: Bool
    var errorMessage: String? = nil
    var connectAction: () -> Void = {}
    
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "headphones")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(Theme.secondary)
            Text("DisconnectedView.title")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.secondary)
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button(action: connectAction) {
                Text(connecting ? "DisconnectedView.connecting" : "DisconnectedView.connect")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(connecting)
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

#Preview {
    DisconnectedView(connecting: false, errorMessage: "Error")
}

#Preview {
    DisconnectedView(connecting: true, errorMessage: "Error")
}
