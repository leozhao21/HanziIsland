import SwiftUI

struct CharacterLearnCard: View {
    let character: HanziCharacter
    let mastery: MasteryLevel

    var body: some View {
        VStack(spacing: 16) {
            Text(character.character)
                .font(.system(size: 96, weight: .medium, design: .rounded))

            Text(character.pinyin)
                .font(.title)
                .foregroundStyle(.secondary)

            Text(character.meaning)
                .font(.title3)

            VStack(alignment: .leading, spacing: 8) {
                Label("生活例句", systemImage: "text.quote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(character.sentence)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Text(mastery.title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding()
    }
}
