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
                let profile = await SupabaseVaultService.shared.currentUserProfile()
                userEmail = profile.email
                userDisplayName = profile.displayName
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
                Text(msg)
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
        guard service.isConfigured else {
            errorMessage = "Cloud vault not configured. Install the supabase-swift SPM package and set SUPABASE_URL / SUPABASE_ANON_KEY in Info.plist, or skip this step and continue offline."
            return
        }
        Task { @MainActor in
            isGenerating = true
            defer { isGenerating = false }
            do {
                let invite = try await service.generateExecutorInvite(
                    estateID: estateID,
                    email: executorEmail
                )
                generatedInvite = invite
                if MFMailComposeViewController.canSendMail() {
                    showMailComposer = true
                }
            } catch {
                errorMessage = error.localizedDescription
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
