import SwiftUI

@main
struct FamilyPrepApp: App {
    @StateObject private var repository: LocalDataRepository

    init() {
        let repo = LocalDataRepository()
        _repository = StateObject(wrappedValue: repo)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(repository)
        }
    }
}
