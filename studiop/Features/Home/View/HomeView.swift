import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home")
                .font(.title)
            Text("Bottom tabs and content will be added in Sprint 8.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
