import SwiftUI

struct SpeakButton: View {
    let title: String
    let spokenText: String
    var prominent: Bool = false

    var body: some View {
        Button {
            SpeechService.shared.speak(spokenText)
        } label: {
            Label(title, systemImage: "speaker.wave.2.fill")
                .font(prominent ? .title3 : .subheadline)
                .frame(maxWidth: prominent ? .infinity : nil)
                .padding(.vertical, prominent ? 12 : 8)
                .padding(.horizontal, prominent ? 16 : 12)
        }
        .buttonStyle(.bordered)
        .tint(.teal)
    }
}
