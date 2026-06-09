import AVFoundation

struct SpeechVoiceOption: Identifiable, Hashable {
    let id: String
    let displayName: String
}

// MARK: - 播放模型
//
// 所有语音统一走「会话队列」：
// 1. 一次 startSession 提交若干条 Utterance，按顺序播放
// 2. 新会话会打断当前会话（stop → didCancel → 播新队列）
// 3. 手动按钮、自动 .task 都调用同一套 API，避免互相取消导致无声
//
// 认识新字：自动 = speakLearnCharacterAuto（仅汉字）
//          手动 = 听字 / 听句子 / 听组成 / 听故事
// 练习题：  自动 = speakQuiz*（进题 .task 触发）
//          手动 = 再听一遍 等

@MainActor
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()

    private static let voiceDefaultsKey = "speechVoiceIdentifier"
    private static let characterRate = AVSpeechUtteranceDefaultSpeechRate * 0.72
    private static let sentenceRate = AVSpeechUtteranceDefaultSpeechRate * 0.85

    private struct QueuedUtterance {
        let text: String
        let rate: Float
        let pauseAfter: TimeInterval
    }

    private let synthesizer = AVSpeechSynthesizer()
    private var activeVoice: AVSpeechSynthesisVoice?

    private var queue: [QueuedUtterance] = []
    private var deferredSession: [QueuedUtterance]?
    private var chainTask: Task<Void, Never>?

    private override init() {
        super.init()
        synthesizer.delegate = self
        reloadVoice()
        activateAudioSession()
    }

    // MARK: - 音色

    static var chineseVoiceOptions: [SpeechVoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("zh") }
            .map { voice in
                SpeechVoiceOption(
                    id: voice.identifier,
                    displayName: localizedName(for: voice)
                )
            }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    var selectedVoiceIdentifier: String {
        UserDefaults.standard.string(forKey: Self.voiceDefaultsKey) ?? ""
    }

    var selectedVoiceDisplayName: String {
        if let activeVoice {
            return Self.localizedName(for: activeVoice)
        }
        return "系统默认"
    }

    func setVoiceIdentifier(_ identifier: String) {
        UserDefaults.standard.set(identifier, forKey: Self.voiceDefaultsKey)
        reloadVoice()
    }

    func reloadVoice() {
        let saved = selectedVoiceIdentifier
        if !saved.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: saved) {
            activeVoice = voice
        } else {
            activeVoice = Self.resolveDefaultChineseVoice()
        }
    }

    func previewVoice() {
        speak("你好，我是识字岛，一起来学汉字吧！")
    }

    // MARK: - 控制

    func stop() {
        cancelChainTask()
        queue.removeAll()
        deferredSession = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - 认识新字

    /// 自动：仅汉字两遍
    func speakLearnCharacterAuto(_ character: HanziCharacter) {
        startSession(characterTwice(character.character))
    }

    /// 手动听字：汉字两遍 + 例句
    func speakCharacterWithPinyin(_ character: HanziCharacter) {
        var items = characterTwice(character.character, pauseBeforeNext: 0.1)
        items.append(.init(text: character.sentence, rate: Self.sentenceRate, pauseAfter: 0))
        startSession(items)
    }

    func speakSentence(_ character: HanziCharacter) {
        let sentence = character.sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sentence.isEmpty else { return }
        startSession([.init(text: sentence, rate: Self.sentenceRate, pauseAfter: 0)])
    }

    func speakComposition(_ character: HanziCharacter) {
        let hint = character.decomposeHint?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let components = character.components ?? []
        guard !hint.isEmpty || !components.isEmpty else { return }

        var items: [QueuedUtterance] = []
        if components.count >= 2 {
            for (index, part) in components.enumerated() {
                items.append(.init(
                    text: part,
                    rate: Self.characterRate,
                    pauseAfter: index < components.count - 1 ? 0.18 : 0.22
                ))
            }
            let partsText = components.map { "「\($0)」" }.joined(separator: "和")
            items.append(.init(
                text: "组成\(partsText)，就是「\(character.character)」。",
                rate: Self.sentenceRate,
                pauseAfter: hint.isEmpty ? 0 : 0.12
            ))
        } else if let part = components.first {
            items.append(.init(text: part, rate: Self.characterRate, pauseAfter: 0.12))
        }
        if !hint.isEmpty {
            items.append(.init(text: hint, rate: Self.sentenceRate, pauseAfter: 0))
        }
        startSession(items)
    }

    func speakEvolution(_ character: HanziCharacter) {
        let hint = character.evolutionHint?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !hint.isEmpty else { return }

        var items: [QueuedUtterance] = []
        if let type = character.evolutionType {
            items.append(.init(
                text: "「\(character.character)」是\(type)字。",
                rate: Self.sentenceRate,
                pauseAfter: 0.12
            ))
        } else {
            items.append(.init(
                text: "一起来听「\(character.character)」的演变故事。",
                rate: Self.sentenceRate,
                pauseAfter: 0.12
            ))
        }
        items.append(.init(text: hint, rate: Self.sentenceRate, pauseAfter: 0))
        startSession(items)
    }

    // MARK: - 练习题

    /// 自动：听音选字 / 认字
    func speakQuizListenChallenge(for character: HanziCharacter) {
        var items: [QueuedUtterance] = [
            .init(text: "听一听，选出你听到的字。", rate: Self.sentenceRate, pauseAfter: 0.35)
        ]
        items.append(contentsOf: characterTwice(character.character))
        startSession(items)
    }

    /// 自动：例句填空
    func speakQuizSentence(_ character: HanziCharacter) {
        speakSentence(character)
    }

    /// 手动：再听一遍（仅汉字）
    func speakCharacter(_ character: HanziCharacter) {
        startSession(characterTwice(character.character))
    }

    // MARK: - 通用

    func speak(_ text: String, rate: Float = sentenceRate) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        startSession([
            .init(
                text: trimmed,
                rate: trimmed.count <= 4 ? Self.characterRate : rate,
                pauseAfter: 0
            )
        ])
    }

    // MARK: - 队列核心

    private func startSession(_ utterances: [QueuedUtterance]) {
        let valid = utterances.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !valid.isEmpty else { return }

        activateAudioSession()
        cancelChainTask()

        if synthesizer.isSpeaking {
            deferredSession = valid
            queue.removeAll()
            synthesizer.stopSpeaking(at: .immediate)
        } else {
            deferredSession = nil
            queue = valid
            speakNextInQueue()
        }
    }

    private func speakNextInQueue() {
        cancelChainTask()
        guard !queue.isEmpty else { return }

        let item = queue.removeFirst()
        synthesizer.speak(makeUtterance(text: item.text, rate: item.rate))

        guard !queue.isEmpty else { return }

        let pause = item.pauseAfter
        chainTask = Task { @MainActor in
            if pause > 0 {
                try? await Task.sleep(for: .seconds(pause))
            }
            guard !Task.isCancelled else { return }
            chainTask = nil
            speakNextInQueue()
        }
    }

    private func characterTwice(_ glyph: String, pauseBeforeNext: TimeInterval = 0) -> [QueuedUtterance] {
        [
            .init(text: glyph, rate: Self.characterRate, pauseAfter: 0.1),
            .init(text: glyph, rate: Self.characterRate * 0.95, pauseAfter: pauseBeforeNext)
        ]
    }

    private func makeUtterance(text: String, rate: Float) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = activeVoice ?? Self.resolveDefaultChineseVoice()
            ?? AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = 0.94
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0
        return utterance
    }

    private func cancelChainTask() {
        chainTask?.cancel()
        chainTask = nil
    }

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .defaultToSpeaker]
            )
            try session.setActive(true, options: [])
        } catch {
            #if DEBUG
            print("[SpeechService] 音频会话激活失败: \(error)")
            #endif
        }
    }

    private static func resolveDefaultChineseVoice() -> AVSpeechSynthesisVoice? {
        let chinese = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("zh") }

        if let enhanced = chinese.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }

        for code in ["zh-CN", "zh-Hans", "zh-TW", "zh-HK"] {
            if let voice = AVSpeechSynthesisVoice(language: code) {
                return voice
            }
        }
        return chinese.first
    }

    private static func localizedName(for voice: AVSpeechSynthesisVoice) -> String {
        let quality = voice.quality == .enhanced ? "（高品质）" : ""
        let locale = voice.language
            .replacingOccurrences(of: "zh-CN", with: "大陆")
            .replacingOccurrences(of: "zh-Hans", with: "简体")
            .replacingOccurrences(of: "zh-TW", with: "台湾")
            .replacingOccurrences(of: "zh-HK", with: "香港")
        return "\(voice.name) · \(locale)\(quality)"
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            // 若已用 chainTask 调度下一条，则不再重复触发
            guard chainTask == nil, !queue.isEmpty else { return }
            speakNextInQueue()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            cancelChainTask()
            if let deferred = deferredSession {
                deferredSession = nil
                queue = deferred
                speakNextInQueue()
            } else {
                queue.removeAll()
            }
        }
    }
}
