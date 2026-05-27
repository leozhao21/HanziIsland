import Foundation

/// 生成四类检测题（PRD 第六节）
struct QuizGeneratorService {
    func generate(
        type: QuizType,
        for target: HanziCharacter,
        from pool: [HanziCharacter]
    ) -> QuizQuestion? {
        let distractors = pool
            .filter { $0.id != target.id }
            .shuffled()
            .prefix(3)
            .map(\.character)

        guard distractors.count == 3 else { return nil }

        switch type {
        case .recognize:
            var options = Array(distractors) + [target.character]
            options.shuffle()
            let correctIndex = options.firstIndex(of: target.character) ?? 0
            return QuizQuestion(
                type: .recognize,
                target: target,
                prompt: "哪个字是「\(target.character)」？",
                options: options,
                correctIndex: correctIndex
            )

        case .pinyin:
            let wrongPinyin = pool.filter { $0.id != target.id }.shuffled().prefix(3).map(\.pinyin)
            var options = wrongPinyin + [target.pinyin]
            options.shuffle()
            let correctIndex = options.firstIndex(of: target.pinyin) ?? 0
            return QuizQuestion(
                type: .pinyin,
                target: target,
                prompt: target.character,
                options: options,
                correctIndex: correctIndex
            )

        case .sentenceFill:
            let blanked = target.sentence.replacingOccurrences(of: target.character, with: "___")
            var options = Array(distractors) + [target.character]
            options.shuffle()
            let correctIndex = options.firstIndex(of: target.character) ?? 0
            return QuizQuestion(
                type: .sentenceFill,
                target: target,
                prompt: blanked,
                options: options,
                correctIndex: correctIndex,
                sentenceTemplate: blanked
            )

        case .image:
            var options = Array(distractors) + [target.character]
            options.shuffle()
            let correctIndex = options.firstIndex(of: target.character) ?? 0
            return QuizQuestion(
                type: .image,
                target: target,
                prompt: "看图选字",
                options: options,
                correctIndex: correctIndex
            )
        }
    }

    func generateMixedSession(
        characters: [HanziCharacter],
        count: Int
    ) -> [QuizQuestion] {
        let types = QuizType.allCases
        var questions: [QuizQuestion] = []
        let shuffled = characters.shuffled()

        for (index, char) in shuffled.prefix(count).enumerated() {
            let type = types[index % types.count]
            if let q = generate(type: type, for: char, from: characters) {
                questions.append(q)
            }
        }
        return questions
    }
}
