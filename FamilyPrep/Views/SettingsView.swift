import SwiftUI
import MessageUI

@MainActor
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appState) private var appState
    @EnvironmentObject private var repository: LocalDataRepository

    @State private var userEmail: String?
    @State private var userDisplayName: String?

    @State private var executors: [EstateAccessRecord] = []
    @State private var isLoadingExecutors: Bool = false
    @State private var showInviteSheet: Bool = false
    @State private var lastGeneratedInvite: ExecutorInvite?
    @State private var generatedInviteForCopy: ExecutorInvite?

    @State private var newExecutorEmail: String = ""
    @State private var isGeneratingInvite: Bool = false

    @State private var isDeletingAccount: Bool = false
    @State private var confirmDeleteEstate: Bool = false
    @State private var errorMessage: String?

    private var isOwner: Bool { appState.isOwner }
    private var currentEstateID: UUID? { appState.currentEstateID }
    private var currentRole: EstateRole? { appState.currentRole }

    private var isEmailValid: Bool {
        let trimmed = newExecutorEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PastelEditorialCanvas()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 28) {
                        headerCard
                            .padding(.top, 20)

                        if isOwner {
                            estateAccessSection
                        } else {
                            executorReadOnlyNote
                        }

                        accountAndDataSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings & Estate Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                async let profile: () = loadProfile()
                async let execs: () = reloadExecutorsIfOwner()
                _ = await (profile, execs)
            }
            .sheet(isPresented: $showInviteSheet) {
                inviteExecutorSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .alert(
                "Delete Account & Reset Estate Data",
                isPresented: $confirmDeleteEstate
            ) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive, action: handleDeleteAccount)
            } message: {
                Text("""
                This permanently deletes:
                • All files uploaded to your estate vault
                • All document metadata, access invites, and executor links
                • Your estate record itself

                This action cannot be undone and your data is unrecoverable.
                """)
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

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.indigo.opacity(0.14))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.indigo)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(userDisplayName ?? userEmail ?? "Signed in user")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let email = userEmail {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    roleBadge
                }

                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var roleBadge: some View {
        if let role = currentRole {
            HStack(spacing: 6) {
                Image(systemName: role == .owner
                      ? "crown.fill"
                      : "briefcase.fill")
                Text(role == .owner ? "Estate Owner" : "Executor")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(role == .owner
                          ? Color.orange.opacity(0.16)
                          : Color.teal.opacity(0.16))
            )
            .foregroundStyle(role == .owner ? Color.orange : Color.teal)
        }
    }

    // MARK: - Estate Access (Owner)

    private var estateAccessSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                sectionHeader(title: "Estate Access & Executors",
                              systemImage: "person.2.fill",
                              tint: .teal)
                Spacer()
                Button(action: { prepareInviteSheet() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Invite Executor")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.teal)
                }
            }

            cardBackground {
                if isLoadingExecutors {
                    HStack {
                        Spacer()
                        ProgressView("Loading executors…")
                        Spacer()
                    }
                    .padding(24)
                } else if executors.isEmpty {
                    emptyExecutorsView
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(executors.enumerated()), id: \.element.id) { idx, exec in
                            executorRow(exec)
                            if idx < executors.count - 1 {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private func executorRow(_ exec: EstateAccessRecord) -> some View {
        let statusTint: Color
        let statusLabel: String
        let statusSymbol: String
        switch exec.status ?? "pending" {
        case "accepted":
            statusTint = .green
            statusLabel = "Active"
            statusSymbol = "checkmark.circle.fill"
        case "revoked":
            statusTint = .red
            statusLabel = "Revoked"
            statusSymbol = "xmark.circle.fill"
        default:
            statusTint = .orange
            statusLabel = "Pending invite"
            statusSymbol = "envelope.badge.clock.fill"
        }

        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(statusTint.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .font(.headline)
                    .foregroundStyle(statusTint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exec.invitedEmail ?? "Unnamed executor")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: statusSymbol)
                        .font(.caption2)
                    Text(statusLabel)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(statusTint)
            }

            Spacer()

            if let code = exec.inviteCode, exec.status == "pending" {
                Button(action: { UIPasteboard.general.string = code }) {
                    HStack(spacing: 4) {
                        Text(code)
                            .font(.system(.callout, design: .monospaced).weight(.semibold))
                        Image(systemName: "doc.on.doc.fill")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.14))
                    )
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: { revoke(exec) }) {
                Label("Revoke", systemImage: "trash.fill")
            }
            .tint(.red)
        }
    }

    private var emptyExecutorsView: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tertiary)
            Text("No executors yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Invite a trusted executor using the button above. They'll receive a 6-character code to claim access.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(24)
    }

    @ViewBuilder
    private var inviteExecutorSheet: some View {
        NavigationStack {
            ZStack {
                PastelEditorialCanvas()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        sheetHeader

                        emailEntryCard

                        if let invite = lastGeneratedInvite {
                            generatedCodeCard(invite)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Invite Executor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        lastGeneratedInvite = nil
                        newExecutorEmail = ""
                        showInviteSheet = false
                    }
                }
            }
        }
    }

    private var sheetHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.teal.opacity(0.16))
                    .frame(width: 46, height: 46)
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundStyle(.teal)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite a trusted Executor")
                    .font(.headline)
                Text("Share this unique 6-character code with them. They'll use it in their app to gain access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emailEntryCard: some View {
        cardBackground {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Executor email")
                        .font(.subheadline.weight(.semibold))

                    TextField("executor@example.com", text: $newExecutorEmail)
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

                Button(action: generateAdditionalInvite) {
                    HStack(spacing: 8) {
                        if isGeneratingInvite {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isGeneratingInvite ? "Generating…" : "Generate Invite Code")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isEmailValid && !isGeneratingInvite ? Color.teal : Color.gray.opacity(0.35))
                    )
                    .foregroundStyle(.white)
                }
                .disabled(!isEmailValid || isGeneratingInvite)
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }

    private func generatedCodeCard(_ invite: ExecutorInvite) -> some View {
        cardBackground {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 0) {
                    Text(invite.inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .tracking(10)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: { UIPasteboard.general.string = invite.inviteCode }) {
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
                    Button(action: { UIPasteboard.general.string = invite.inviteCode }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)

                    Button(action: { generatedInviteForCopy = invite }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Share")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.teal.opacity(0.12)))
                        .foregroundStyle(.teal)
                    }
                    .buttonStyle(.plain)
                    .sheet(item: $generatedInviteForCopy) { inv in
                        ActivityView(activityItems: [shareText(for: inv)])
                            .ignoresSafeArea()
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Executor-only notice

    private var executorReadOnlyNote: some View {
        cardBackground {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.teal)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("You are viewing as an Executor")
                        .font(.headline)
                    Text("Estate ownership and executor invitations are managed by the Estate Owner only.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Account & Data Management

    private var accountAndDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Account & Data",
                          systemImage: "tray.and.arrow.down.fill",
                          tint: .red)

            cardBackground {
                VStack(alignment: .leading, spacing: 0) {
                    if isOwner {
                        Button(role: .destructive, action: { confirmDeleteEstate = true }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.red.opacity(0.14))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "trash.fill")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete Account & Reset Estate Data")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                    Text("Permanently remove your estate vault files, executors, and records.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                if isDeletingAccount {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.red)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeletingAccount)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contact Estate Owner")
                                .font(.headline)
                            Text("If you no longer need executor access, please ask the Estate Owner to revoke your invitation.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
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

    private func loadProfile() async {
        let (email, name) = await SupabaseVaultService.shared.currentUserProfile()
        userEmail = email
        userDisplayName = name
    }

    private func reloadExecutorsIfOwner() async {
        guard isOwner, let eid = currentEstateID else { return }
        let service = SupabaseVaultService.shared
        guard service.isConfigured else {
            executors = []
            return
        }
        isLoadingExecutors = true
        defer { isLoadingExecutors = false }
        do {
            executors = try await service.fetchExecutors(for: eid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func prepareInviteSheet() {
        newExecutorEmail = ""
        lastGeneratedInvite = nil
        showInviteSheet = true
    }

    private func generateAdditionalInvite() {
        guard let eid = currentEstateID else { return }
        let service = SupabaseVaultService.shared
        NSLog("FamilyPrepUI Settings generateAdditionalInvite — estateID=\(eid.uuidString), email=\(newExecutorEmail)")
        guard service.isConfigured else {
            errorMessage = "Cloud vault not configured. Add supabase-swift SPM package and set SUPABASE_URL / SUPABASE_ANON_KEY in Info.plist."
            return
        }
        Task {
            isGeneratingInvite = true
            defer { isGeneratingInvite = false }
            do {
                let invite = try await service.generateExecutorInvite(
                    estateID: eid,
                    email: newExecutorEmail
                )
                lastGeneratedInvite = invite
                NSLog("FamilyPrepUI Settings ✅ SUCCESS — invite code = \(invite.inviteCode)")
                await reloadExecutorsIfOwner()
            } catch {
                let ns = error as NSError
                NSLog("FamilyPrepUI Settings ❌ ERROR — domain=\(ns.domain) code=\(ns.code) msg=\(ns.localizedDescription)")
                errorMessage = HumanReadableError.message(for: error)
            }
        }
    }

    private func revoke(_ exec: EstateAccessRecord) {
        let service = SupabaseVaultService.shared
        guard service.isConfigured else {
            errorMessage = "Cloud vault not configured — cannot revoke access offline."
            return
        }
        Task {
            do {
                try await service.revokeExecutorAccess(exec.id)
                await reloadExecutorsIfOwner()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleDeleteAccount() {
        guard let eid = currentEstateID else { return }
        let service = SupabaseVaultService.shared
        Task {
            isDeletingAccount = true
            defer { isDeletingAccount = false }
            do {
                if service.isConfigured {
                    try await service.deleteEstateAndAllData(estateID: eid)
                }
                try repository.deleteAllLocalData()
                appState.resetToOnboarding()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func shareText(for invite: ExecutorInvite) -> String {
        """
        Family Prep Executor Invite

        Invite code: \(invite.inviteCode)

        1. Download the Family Prep app
        2. Sign in with your own account
        3. Tap "I Have an Executor Invite Code" and enter the code above
        """
    }
}

// MARK: - Share sheet wrapper

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Make ExecutorInvite Identifiable for sheet(item:)
extension ExecutorInvite: Identifiable {
    var id: String { inviteCode }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(\.appState, AppState.shared)
    }
}
