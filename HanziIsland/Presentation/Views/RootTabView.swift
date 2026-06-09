import SwiftUI

struct RootTabView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        TabView {
            KidHomeView(viewModel: viewModel)
                .tabItem { Label("玩", systemImage: "house.fill") }

            LearnedTabView(viewModel: viewModel)
                .tabItem { Label("已学", systemImage: "book.fill") }

            GrowthIslandView(viewModel: viewModel)
                .tabItem { Label("星星", systemImage: "star.fill") }
        }
        .tint(Color("AccentGreen"))
    }
}
