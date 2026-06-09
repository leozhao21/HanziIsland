import SwiftUI

struct CharacterLearnCard: View {
    let character: HanziCharacter
    let mastery: MasteryLevel

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                Text(character.character)
                    .font(.system(size: 120, weight: .bold, design: .rounded))

                KidInlineAudioButton(label: "听字", iconSize: 32) {
                    SpeechService.shared.speakCharacterWithPinyin(character)
                }
            }

            Text(character.pinyin)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 10) {
                Text(character.sentence)
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                KidInlineAudioButton(iconSize: 30) {
                    SpeechService.shared.speakSentence(character)
                }
                .accessibilityLabel("听句子")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

            CharacterDecomposeSection(character: character)
        }
        .padding(.vertical, 8)
        .task(id: character.id) {
            SpeechService.shared.speakLearnCharacterAuto(character)
        }
    }
}
