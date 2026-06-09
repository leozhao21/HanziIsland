import SwiftUI

/// 汉字拆解学习区块：展示部件拆解（保留文字），讲解仅语音
struct CharacterDecomposeSection: View {
    let character: HanziCharacter

    var body: some View {
        if character.showsCompositionSection || character.hasEvolution {
            VStack(alignment: .leading, spacing: 20) {
                if character.showsCompositionSection {
                    compositionBlock
                }
                if character.hasEvolution {
                    evolutionBlock
                }
            }
        }
    }

    // MARK: - 组成拆解（保留部件文字，讲解仅听音）

    @ViewBuilder
    private var compositionBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(emoji: "🧩", title: "这个字怎么组成？")

            HStack(alignment: .center, spacing: 10) {
                if character.showsComponentBreakdown, let components = character.components {
                    componentRow(components)
                }

                Spacer(minLength: 0)

                KidInlineAudioButton(label: "听组成", iconSize: 32) {
                    SpeechService.shared.speakComposition(character)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 演变（讲解仅听音）

    private var evolutionBlock: some View {
        HStack(spacing: 8) {
            sectionHeader(emoji: "📜", title: "汉字演变故事")
            if let type = character.evolutionType {
                Text(type)
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
            KidInlineAudioButton(label: "听故事", iconSize: 32) {
                SpeechService.shared.speakEvolution(character)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 共用组件

    private func sectionHeader(emoji: String, title: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.title2)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
        }
    }

    @ViewBuilder
    private func componentRow(_ components: [String]) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(components.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text("+")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.7))
                }
                componentChip(part)
            }
            if components.count >= 2 {
                Text("=")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.7))
                componentChip(character.character, highlighted: true)
            }
        }
    }

    private func componentChip(_ glyph: String, highlighted: Bool = false) -> some View {
        Text(glyph)
            .font(.system(size: highlighted ? 44 : 40, weight: .bold, design: .rounded))
            .frame(minWidth: 56, minHeight: 56)
            .padding(.horizontal, 8)
            .background(
                highlighted ? Color.orange.opacity(0.22) : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                if highlighted {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 2)
                }
            }
    }
}
