import SwiftUI
import SwiftData

@main
struct HanziIslandApp: App {
    private let containerResult = AppModelContainer.make()
    @State private var viewModel = AppViewModel()

    init() {
        // 启动时预热语音引擎并配置音频会话
        Task { @MainActor in
            _ = SpeechService.shared
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                AppRootView(viewModel: viewModel, modelContainer: container)
                    .modelContainer(container)
            case .failure(let error):
                ContentUnavailableView {
                    Label("无法启动", systemImage: "externaldrive.badge.xmark")
                } description: {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

private struct AppRootView: View {
    @Bindable var viewModel: AppViewModel
    let modelContainer: ModelContainer
    @State private var isBootstrapping = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if viewModel.isLoaded {
                RootTabView(viewModel: viewModel)
                    .transition(.opacity)
            } else if let error = viewModel.loadError {
                ContentUnavailableView {
                    Label("加载失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("重试") {
                        Task { await bootstrap(force: true) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text(viewModel.loadStatus)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLoaded)
        .task {
            await bootstrap(force: false)
        }
    }

    @MainActor
    private func bootstrap(force: Bool) async {
        if isBootstrapping { return }
        if !force && viewModel.isLoaded { return }

        isBootstrapping = true
        defer { isBootstrapping = false }

        if force {
            viewModel.isLoaded = false
            viewModel.loadError = nil
        }

        viewModel.configure(modelContext: modelContainer.mainContext)
        await viewModel.load()
    }
}
