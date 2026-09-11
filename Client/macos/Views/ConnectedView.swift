//import SwiftUI
//
//struct ConnectedView: View {
//    var body: some View {
//        ScrollView(showsIndicators: false) {
//            VStack(spacing: 16) {
//                deviceHero
//                ambientCard
//                if model.state.mode == .ambientSound {
//                    ambientLevelCard
//                }
//                if model.state.supportsEqualizer {
//                    equalizerCard
//                    dseeCard
//                }
//                if model.state.hasAdaptiveVolume || model.state.hasSpeakToChat || model.state.hasAutoPowerOff {
//                    settingsCard
//                }
//                if let error = model.state.errorMessage {
//                    Text(error)
//                        .font(.system(size: 12))
//                        .foregroundColor(.red.opacity(0.9))
//                }
//            }
//            .padding(20)
//        }
//    }
//}
//
//#Preview {
//    ConnectedView()
//}
