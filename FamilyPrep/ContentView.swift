import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var repository: LocalDataRepository

    var body: some View {
        HomeDashboardView()
            .alert(
                "Something went wrong",
                isPresented: .constant(repository.errorMessage != nil),
                presenting: repository.errorMessage
            ) { _ in
                Button("OK") {
                    repository.errorMessage = nil
                }
            } message: { msg in
                Text(msg)
            }
    }
}

#Preview {
    let repo = LocalDataRepository()
    return ContentView()
        .environmentObject(repo)
}
