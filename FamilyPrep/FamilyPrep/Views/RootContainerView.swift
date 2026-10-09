import SwiftUI

@MainActor
struct RootContainerView: View {
    @EnvironmentObject private var repository: LocalDataRepository
    private var appState: AppState { AppState.shared }

    @State private var showWelcomeOwner: Bool = false
    @State private var showClaimInvite: Bool = false
    @State private var pendingOwnerEstateID: UUID?
    @State private var actionError: String?

    var body: some View {
        ZStack {
            switch appState.phase {
            case .loading:
                ZStack {
                    PastelEditorialCanvas()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.3)
                        Text("Preparing your vault…")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity)

            case .onboardingRequired:
                OnboardingView(
                    onSetupEstate: handleSetupEstate,
                    onClaimInvite: { showClaimInvite = true }
                )
                .transition(.opacity)
                .sheet(isPresented: $showClaimInvite) {
                    InviteCodeClaimView(
                        onBack: { showClaimInvite = false },
                        onClaimed: handleInviteClaimed
                    )
                }

            case .welcomeOwner(let estateID):
                WelcomeOwnerView(
                    estateID: estateID,
                    onDismiss: { appState.completeOwnerWelcome(estateID: estateID) }
                )

            case .onboarded:
                ContentView()
                    .environment(\.appState, appState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phaseIdentity)
        .task {
            await bootstrap()
        }
        .alert(
            "Action failed",
            isPresented: .constant(actionError != nil),
            presenting: actionError
        ) { _ in
            Button("OK") { actionError = nil }
        } message: { msg in
            Text(msg)
        }
    }

    private var phaseIdentity: Int {
        switch appState.phase {
        case .loading: return 0
        case .onboardingRequired: return 1
        case .welcomeOwner: return 2
        case .onboarded: return 3
        }
    }

    // MARK: - Flow actions

    private func bootstrap() async {
        await appState.resolve()
    }

    private func handleSetupEstate() {
        let service = SupabaseVaultService.shared
        let offlineFallbackID = pendingOwnerEstateID ?? UUID()

        // If Supabase isn't configured at all, jump straight to offline owner-welcome
        // with a local UUID. No cloud sync will occur until SPM/Info.plist is set up.
        guard service.isConfigured else {
            pendingOwnerEstateID = offlineFallbackID
            appState.completeOwnerWelcome(estateID: offlineFallbackID)
            return
        }

        Task {
            do {
                let estateID = try await service.createDefaultOwnerEstate()
                pendingOwnerEstateID = estateID
                appState.showOwnerWelcome(estateID: estateID)
            } catch {
                // First-launch cloud operations can fail for many benign reasons
                // (RLS policies not yet bootstrapped, no auth session, offline).
                // Don't block the user: fall back to a local UUID and let them
                // proceed; cloud operations will be attempted again from Settings
                // once Supabase sign-in + RLS are wired up.
                print("ℹ️ createDefaultOwnerEstate fell back to local mode: \(error.localizedDescription)")
                let localID = pendingOwnerEstateID ?? UUID()
                pendingOwnerEstateID = localID
                appState.showOwnerWelcome(estateID: localID)
            }
        }
    }

    private func handleInviteClaimed(estateID: UUID) {
        showClaimInvite = false
        appState.completeInviteClaim(estateID: estateID)
    }
}

// MARK: - Environment access to current role

private struct AppStateKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AppState = AppState.shared
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}

#Preview {
    let repo = LocalDataRepository()
    RootContainerView()
        .environmentObject(repo)
        .environment(\.appState, AppState.shared)
}
