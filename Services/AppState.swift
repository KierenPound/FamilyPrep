import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {

    static let shared = AppState()

    enum ResolutionPhase {
        case loading
        case onboardingRequired
        case welcomeOwner(estateID: UUID)
        case onboarded(estateID: UUID, role: EstateRole)
    }

    private(set) var phase: ResolutionPhase = .loading

    private(set) var currentEstateID: UUID?
    private(set) var currentRole: EstateRole?

    var isOwner: Bool { currentRole == .owner }
    var isExecutor: Bool { currentRole == .executor }

    private init() {}

    func resolve() async {
        phase = .loading

        let service = SupabaseVaultService.shared
        guard service.isConfigured else {
            phase = .onboardingRequired
            return
        }

        do {
            if let (estateID, role) = try await service.resolveCurrentUserEstateAndRole() {
                currentEstateID = estateID
                currentRole = role
                phase = .onboarded(estateID: estateID, role: role)
                return
            }
        } catch {
            print("⚠️ AppState.resolve role query failed: \(error.localizedDescription)")
        }

        phase = .onboardingRequired
    }

    func completeOwnerWelcome(estateID: UUID) {
        currentEstateID = estateID
        currentRole = .owner
        phase = .onboarded(estateID: estateID, role: .owner)
    }

    func completeInviteClaim(estateID: UUID) {
        currentEstateID = estateID
        currentRole = .executor
        phase = .onboarded(estateID: estateID, role: .executor)
    }

    func showOwnerWelcome(estateID: UUID) {
        currentEstateID = estateID
        currentRole = .owner
        phase = .welcomeOwner(estateID: estateID)
    }

    func resetToOnboarding() {
        currentEstateID = nil
        currentRole = nil
        phase = .onboardingRequired
    }
}
