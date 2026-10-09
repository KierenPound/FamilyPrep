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

    var isOwner: Bool { effectiveRole == .owner }
    var isExecutor: Bool { effectiveRole == .executor }

    private(set) var devOverrideRole: EstateRole?

    private enum Keys {
        static let devOverrideRole = "AppState.devOverrideRole"
    }

    var effectiveRole: EstateRole? {
        devOverrideRole ?? currentRole
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.devOverrideRole),
           let r = EstateRole(rawValue: raw) {
            devOverrideRole = r
        }
    }

    /// Dev-only override. Swaps the perceived role immediately (UI gating),
    /// persists across launches, and does NOT touch the cloud estate_access
    /// rows or RLS. Pass nil to clear the override and use the real role.
    @discardableResult
    func devSetRoleOverride(_ role: EstateRole?) -> Bool {
        NSLog("FamilyPrepApp AppState.devSetRoleOverride → \(role?.rawValue ?? "nil") (was \(devOverrideRole?.rawValue ?? "nil"), real=\(currentRole?.rawValue ?? "nil"))")
        devOverrideRole = role
        if let r = role {
            UserDefaults.standard.set(r.rawValue, forKey: Keys.devOverrideRole)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.devOverrideRole)
        }

        // If we're already onboarded, keep the phase but refresh effective role.
        // If the user had no role yet (e.g. offline-guest post-skip) but picks a
        // role, we still need a plausible phase so gated UI continues to work.
        switch phase {
        case .onboarded(let eid, _):
            if let r = role ?? currentRole {
                phase = .onboarded(estateID: eid, role: r)
            }
        case .welcomeOwner(let eid):
            if let r = role {
                phase = .onboarded(estateID: eid, role: r)
            }
        default:
            break
        }

        return true
    }

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
                let effective = devOverrideRole ?? role
                phase = .onboarded(estateID: estateID, role: effective)
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
        let effective = devOverrideRole ?? .owner
        phase = .onboarded(estateID: estateID, role: effective)
    }

    func completeInviteClaim(estateID: UUID) {
        currentEstateID = estateID
        currentRole = .executor
        let effective = devOverrideRole ?? .executor
        phase = .onboarded(estateID: estateID, role: effective)
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
