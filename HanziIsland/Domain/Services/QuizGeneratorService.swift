import Foundation

/// 生成三类检测题（PRD 第六节）
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
                prompt: "听读音，选出正确的字",
                options: options,
                correctIndex: correctIndex
            )

        case .listenPick:
            var options = Array(distractors) + [target.character]
            options.shuffle()
            let correctIndex = options.firstIndex(of: target.character) ?? 0
            return QuizQuestion(
                type: .listenPick,
                target: target,
                prompt: "听一听，选出听到的字",
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
        }
    }

    func generateMixedSession(
        characters: [HanziCharacter],
        count: Int,
        types: [QuizType] = QuizType.allCases,
        requiredCharacters: [HanziCharacter] = []
    ) -> [QuizQuestion] {
        guard !types.isEmpty, !characters.isEmpty else { return [] }

        var questions: [QuizQuestion] = []
        var usedIds = Set<String>()
        var typeIndex = 0

        for char in requiredCharacters where characters.contains(where: { $0.id == char.id }) {
            let type = types[typeIndex % types.count]
            typeIndex += 1
            if let q = generate(type: type, for: char, from: characters) {
                questions.append(q)
                usedIds.insert(char.id)
            }
        }

        let remaining = max(0, count - questions.count)
        if remaining > 0 {
            let extras = characters.filter { !usedIds.contains($0.id) }.shuffled()
            for char in extras.prefix(remaining) {
                let type = types[typeIndex % types.count]
                typeIndex += 1
                if let q = generate(type: type, for: char, from: characters) {
                    questions.append(q)
                }
            }
        }

        return questions.shuffled()
    }
}
