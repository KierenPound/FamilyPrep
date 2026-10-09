import SwiftUI

@main
struct FamilyPrepApp: App {
    @StateObject private var repository: LocalDataRepository

    init() {
        let repo = LocalDataRepository()
        _repository = StateObject(wrappedValue: repo)
        SupabaseVaultService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(repository)
                .environment(\.appState, AppState.shared)
        }
    }
}
