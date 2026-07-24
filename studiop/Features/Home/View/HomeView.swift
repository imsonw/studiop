import SwiftUI

struct HomeView: View {
    let appState: AppState

    var body: some View {
        NavigationStack {
            VStack {
                Text("Home")
                    .font(.title)
                Text("Bottom tabs and content will be added in Sprint 9.")
                    .foregroundStyle(.secondary)

                // Temporary bridges to Sprint 6/7 feature areas -- the real navigation entry
                // point is the bottom tab shell (Sprint 9's F-028), not built yet.
                NavigationLink("Account") {
                    ProfileView(appState: appState)
                }
                .padding(.top)

                NavigationLink("Store") {
                    StorefrontView()
                }

                NavigationLink("Favorites") {
                    FavoritesView()
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HomeView(appState: AppState())
}
