import SwiftUI

@MainActor
struct OnboardingView: View {

    enum Destination: Hashable {
        case setupEstate
        case claimInvite
    }

    var onSetupEstate: () -> Void
    var onClaimInvite: () -> Void

    @State private var isSigningIn: Bool = false
    @State private var signInError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PastelEditorialCanvas()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroHeader
                            .padding(.top, 24)

                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader(
                                title: "Sign in to link your identity",
                                systemImage: "apple.logo",
                                tint: .primary
                            )

                            SignInWithAppleButton(style: .standard) {
                                Task { await handleSignInWithApple() }
                            }
                            .opacity(isSigningIn ? 0.6 : 1.0)
                            .overlay(alignment: .trailing) {
                                if isSigningIn {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                        .padding(.trailing, 20)
                                }
                            }

                            Text("Optional: Sign in with your Apple ID to connect your cloud identity. You can also continue as a guest and sign in later.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 2)
                        }

                        Divider().padding(.vertical, 4)

                        optionCard(
                            title: "Setup My Estate",
                            subtitle: "I am the Estate Owner. Create my secure vault and invite an executor later.",
                            systemImage: "house.fill",
                            tint: .indigo,
                            action: onSetupEstate
                        )

                        optionCard(
                            title: "I Have an Executor Invite Code",
                            subtitle: "Someone has invited me to act as an Executor. Enter the 6-character code to gain access.",
                            systemImage: "envelope.open.fill",
                            tint: .teal,
                            action: onClaimInvite
                        )

                        footerNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.large)
            .alert(
                "Sign in with Apple failed",
                isPresented: .constant(signInError != nil),
                presenting: signInError
            ) { _ in
                Button("OK") { signInError = nil }
            } message: { msg in
                Text(msg)
            }
        }
    }

    private func handleSignInWithApple() async {
        let service = SupabaseVaultService.shared
        guard service.isConfigured else {
            signInError = "Cloud vault not configured yet. Continue as guest to set up your estate locally, then sign in from Settings."
            return
        }
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            let cred = try await runAppleSignIn()
            _ = try await service.signInWithApple(
                identityToken: cred.identityToken,
                nonce: cred.nonce,
                email: cred.email,
                givenName: cred.givenName,
                familyName: cred.familyName
            )
        } catch {
            let ns = error as NSError
            NSLog("FamilyPrepUI Onboarding ❌ signInWithApple: \(ns.domain) \(ns.code) \(ns.localizedDescription)")
            signInError = HumanReadableError.message(for: error)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.indigo.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.indigo)
            }

            Text("Welcome to Family Prep")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Let's get your secure estate vault set up in under a minute.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionCard(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 52, height: 52)
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.callout.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 14)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var footerNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("Your estate data is encrypted at rest and only accessible by you and any executors you explicitly invite. No one on the Family Prep team can read your documents.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
    }

    private func sectionHeader(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    OnboardingView(
        onSetupEstate: {},
        onClaimInvite: {}
    )
}
