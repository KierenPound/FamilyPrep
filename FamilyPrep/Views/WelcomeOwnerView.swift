import SwiftUI
import MessageUI

@MainActor
struct WelcomeOwnerView: View {

    let estateID: UUID
    var onDismiss: () -> Void

    @State private var userEmail: String?
    @State private var userDisplayName: String?

    @State private var executorEmail: String = ""
    @State private var isGenerating: Bool = false
    @State private var generatedInvite: ExecutorInvite?
    @State private var errorMessage: String?
    @State private var showMailComposer: Bool = false

    private var isEmailValid: Bool {
        let trimmed = executorEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PastelEditorialCanvas()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        welcomeHeader
                            .padding(.top, 24)

                        accountCard

                        inviteExecutorCard

                        if generatedInvite != nil {
                            inviteCodeCard
                        }

                        continueButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(.subheadline.bold())
                    }
                    .disabled(generatedInvite == nil)
                }
            }
            .task {
                let service = SupabaseVaultService.shared
                NSLog("FamilyPrepUI WelcomeOwnerView appeared — service.isConfigured=\(service.isConfigured), isAuthenticated=\(service.isAuthenticated), estateID=\(estateID.uuidString)")
                let profile = await service.currentUserProfile()
                userEmail = profile.email
                userDisplayName = profile.displayName
                NSLog("FamilyPrepUI WelcomeOwnerView profile — email=\(String(describing: profile.email)), displayName=\(String(describing: profile.displayName))")
            }
            .sheet(isPresented: $showMailComposer) {
                if MFMailComposeViewController.canSendMail(), let invite = generatedInvite {
                    MailComposeView(
                        recipient: invite.invitedEmail,
                        subject: "Your Family Prep Executor Invite",
                        body: emailBody(for: invite)
                    )
                    .ignoresSafeArea()
                }
            }
            .alert(
                "Something went wrong",
                isPresented: .constant(errorMessage != nil),
                presenting: errorMessage
            ) { _ in
                Button("OK") { errorMessage = nil }
            } message: { msg in
                // LAST-LINE-OF-DEFENCE: beautify AGAIN at render-time. Any raw
                // Postgres/RLS "permission denied" that leaked past every other
                // layer is caught here and never shown to the user verbatim.
                let wrappedError = NSError(
                    domain: "FamilyPrepUI",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: msg]
                )
                Text(HumanReadableError.message(for: wrappedError))
            }
        }
    }

    // MARK: - Sections

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.green)
            }

            Text("Welcome to Family Prep")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("You are set up as the Estate Owner.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Your account",
                          systemImage: "person.crop.circle.fill",
                          tint: .blue)

            cardBackground {
                VStack(alignment: .leading, spacing: 0) {
                    accountRow(label: "Name",
                               value: userDisplayName ?? "Signed in user",
                               accent: .blue)

                    Divider()

                    accountRow(label: "Email",
                               value: userEmail ?? "No email on file",
                               accent: .blue)

                    Divider()

                    accountRow(label: "Role",
                               value: "Estate Owner",
                               accent: .green,
                               valueBold: true)
                }
            }
        }
    }

    private var inviteExecutorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Invite an Executor",
                          systemImage: "envelope.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    Text("An executor helps carry out the instructions in your estate. You can invite someone now or skip this step and come back to it later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Executor email")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        TextField("executor@example.com", text: $executorEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.tertiarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.6)
                            )
                    }

                    Button(action: generateInviteTapped) {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGenerating ? "Generating…" : "Generate Invite Code")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isEmailValid && !isGenerating ? Color.teal : Color.gray.opacity(0.35))
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(!isEmailValid || isGenerating)
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var inviteCodeCard: some View {
        if let invite = generatedInvite {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Invite Code Ready",
                              systemImage: "number.square.fill",
                              tint: .orange)

                cardBackground {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Share this code with your executor so they can claim access when they sign in to Family Prep:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 0) {
                            Text(invite.inviteCode)
                                .font(.system(size: 34, weight: .bold, design: .monospaced))
                                .tracking(10)
                                .foregroundStyle(.primary)

                            Spacer()

                            Button(action: { copyCode(invite.inviteCode) }) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.orange.opacity(0.14))
                                    )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.orange.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 0.8)
                        )

                        HStack(spacing: 10) {
                            Button(action: { copyCode(invite.inviteCode) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.12))
                                )
                                .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)

                            Button(action: { showMailComposer = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "envelope.fill")
                                    Text("Send via Email")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.teal.opacity(0.12))
                                )
                                .foregroundStyle(.teal)
                            }
                            .buttonStyle(.plain)
                            .disabled(!MFMailComposeViewController.canSendMail())
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Keep this code safe. It grants full executor access to the estate vault.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var continueButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 8) {
                Text(generatedInvite != nil ? "Finish & Go to Dashboard" : "Skip for Now & Go to Dashboard")
                    .font(.headline)
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.indigo)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
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

    private func cardBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
    }

    private func accountRow(label: String, value: String, accent: Color, valueBold: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)

            Text(value)
                .font(valueBold ? .body.bold() : .body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func generateInviteTapped() {
        let service = SupabaseVaultService.shared
        NSLog("FamilyPrepUI generateInviteTapped BEGIN — service.isConfigured=\(service.isConfigured), estateID=\(estateID.uuidString), email=\(executorEmail)")
        guard service.isConfigured else {
            errorMessage = "Cloud vault not configured. Install the supabase-swift SPM package and set SUPABASE_URL / SUPABASE_ANON_KEY in Info.plist, or skip this step and continue offline."
            NSLog("FamilyPrepUI ❌ early return — SupabaseVaultService.isConfigured is false")
            return
        }
        Task {
            isGenerating = true
            defer { isGenerating = false }
            do {
                NSLog("FamilyPrepUI calling generateExecutorInvite…")
                let invite = try await service.generateExecutorInvite(
                    estateID: estateID,
                    email: executorEmail
                )
                NSLog("FamilyPrepUI ✅ SUCCESS — invite code = \(invite.inviteCode)")
                generatedInvite = invite
            } catch {
                let ns = error as NSError
                NSLog("FamilyPrepUI ❌ ERROR — domain=\(ns.domain) code=\(ns.code) msg=\(ns.localizedDescription) userInfo=\(ns.userInfo)")
                errorMessage = HumanReadableError.message(for: error)
            }
        }
    }

    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
    }

    private func emailBody(for invite: ExecutorInvite) -> String {
        """
        Hi,

        I'm setting up my estate in Family Prep and I'd like you to act as my Executor.

        Please download the Family Prep app, sign in, and enter this invite code:

        🔑 \(invite.inviteCode)

        Once you enter the code you'll be granted secure access to help manage my estate.

        — Family Prep
        """
    }
}

// MARK: - Error beautifier (never surface raw Postgres/RPC messages to the user)

enum HumanReadableError {
    static func message(for error: Error) -> String {
        let ns = error as NSError
        let msg = ns.localizedDescription.lowercased()
        let domain = ns.domain.lowercased()

        // -------------------------------------------------------------------
        // 1. SupabaseVaultService codes we explicitly throw (friendly paths)
        // -------------------------------------------------------------------
        if domain == "supabasevault" {
            switch ns.code {
            case 201, 202:
                return ns.localizedDescription
            case 203:
                return ns.localizedDescription
            case 501:
                return ns.localizedDescription
            case 100 where msg.contains("invite code must be 6"):
                return ns.localizedDescription
            case 100 where msg.contains("executor email is required"):
                return ns.localizedDescription
            case 100 where msg.contains("failed to generate a unique"):
                return ns.localizedDescription
            case 100 where msg.contains("invalid or already claimed"):
                return ns.localizedDescription
            default:
                break
            }
        }

        // -------------------------------------------------------------------
        // 2. Catch-all known patterns: Postgres RLS, network, 4xx/5xx HTTP
        // -------------------------------------------------------------------
        if msg.contains("permission denied")
            || msg.contains("row level security")
            || msg.contains("policy")
            || msg.contains("42501")
            || ns.code == 403 {
            return """
            Your signed-in identity and your cloud estate aren't linked yet.
            Try signing out of Family Prep, signing back in, then tapping Generate Invite Code again.
            If it still fails, open Supabase → SQL Editor and run the file
            supabase/migrations/harden_rls_execute_grants.sql, then re-launch the app.
            """
        }

        if msg.contains("could not connect")
            || msg.contains("offline")
            || msg.contains("timed out")
            || msg.contains("network")
            || ns.code == -1009 || ns.code == -1001 || ns.code == -1005 || ns.code == -1004 {
            return "Your device seems offline. Check your Wi-Fi/cellular connection and try again."
        }

        if msg.contains("duplicate key") || msg.contains("23505") || msg.contains("unique") {
            if msg.contains("invite_code_unique") || msg.contains("pending_email") {
                return "This email was already sent an invite. Check their inbox for the code, or revoke the old invite in Settings → Executors."
            }
            return "A record like this already exists. Refresh and try again."
        }

        if msg.contains("auth session missing") || msg.contains("not authenticated") || msg.contains("please sign in") {
            return """
            Sign in required to send an invite code.
            Tap Continue as Guest / Sign in with Apple on the onboarding screen first,
            then return here to invite your executor.
            """
        }

        if ns.code >= 500 || msg.contains("server") {
            return "Supabase returned a server error (HTTP \(ns.code)). Try again in a moment."
        }

        if ns.code >= 400 && ns.code < 500 {
            return "Family Prep couldn't complete that request. If you just signed up, close the app and re-launch it once to let your account finish provisioning, then try again."
        }

        // -------------------------------------------------------------------
        // 3. Absolute last-resort fallback — NEVER surface raw msg to user
        // -------------------------------------------------------------------
        return """
        Invite couldn't be created right now.
        Close and re-launch Family Prep, sign out and back in, then try again.
        (For support: SupabaseVault code=\(ns.code) domain=\(ns.domain).)
        """
    }
}

// MARK: - Mail helper

private struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    WelcomeOwnerView(estateID: UUID(), onDismiss: {})
}
