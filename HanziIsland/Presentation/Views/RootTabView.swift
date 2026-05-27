import SwiftUI

struct RootTabView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem { Label("学习", systemImage: "book.fill") }

            LearnFlowView(viewModel: viewModel)
                .tabItem { Label("今日", systemImage: "sun.max.fill") }

            GrowthIslandView(viewModel: viewModel)
                .tabItem { Label("成长岛", systemImage: "star.fill") }

            ParentCenterView(viewModel: viewModel)
                .tabItem { Label("家长", systemImage: "person.2.fill") }
        }
        .tint(Color.accentColor)
    }
}
