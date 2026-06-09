import SwiftUI

/// 应用设置（家长中心内）
struct SettingsView: View {
    @State private var selectedId: String = SpeechService.shared.selectedVoiceIdentifier
    private let voices = SpeechService.chineseVoiceOptions

    var body: some View {
        List {
            Section {
                if voices.isEmpty {
                    ContentUnavailableView {
                        Label("暂无中文语音", systemImage: "speaker.slash")
                    } description: {
                        Text("请先在 iPhone 系统设置中下载中文朗读声音。")
                    } actions: {
                        Button("打开系统设置") {
                            openSystemAccessibilitySettings()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                } else {
                    voiceRow(id: "", title: "系统默认", subtitle: "自动选择中文语音")

                    ForEach(voices) { voice in
                        voiceRow(
                            id: voice.id,
                            title: voice.displayName,
                            subtitle: nil
                        )
                    }
                }
            } header: {
                Text("中文朗读音色")
            } footer: {
                Text("学字与答题时的朗读声音。更多音色：设置 → 辅助功能 → 朗读内容 → 声音 → 中文")
            }

            Section {
                Button {
                    SpeechService.shared.setVoiceIdentifier(selectedId)
                    SpeechService.shared.previewVoice()
                } label: {
                    Label("试听当前音色", systemImage: "play.circle.fill")
                }
                .disabled(voices.isEmpty && selectedId.isEmpty)

                Button {
                    openSystemAccessibilitySettings()
                } label: {
                    Label("去系统下载更多中文语音", systemImage: "arrow.up.forward.app")
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            selectedId = SpeechService.shared.selectedVoiceIdentifier
        }
    }

    @ViewBuilder
    private func voiceRow(id: String, title: String, subtitle: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(Color(uiColor: .label))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            Spacer()
            if selectedId == id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedId = id
            SpeechService.shared.setVoiceIdentifier(id)
            SpeechService.shared.previewVoice()
        }
    }

    private func openSystemAccessibilitySettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
