import SwiftUI

@MainActor
struct InviteCodeClaimView: View {

    var onBack: () -> Void
    var onClaimed: (UUID) -> Void

    @State private var code: String = ""
    @State private var isClaiming: Bool = false
    @State private var errorMessage: String?
    @State private var shakeTrigger: Bool = false

    private var codeIsComplete: Bool {
        code.count == 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PastelEditorialCanvas()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        heroHeader
                            .padding(.top, 24)

                        codeEntryCard
                            .modifier(Shake(animatableData: shakeTrigger ? 1 : 0))

                        backHint
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Enter Invite Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.subheadline.bold())
                    }
                }
            }
            .alert(
                "Unable to claim code",
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

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.teal.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }

            Text("Enter your Executor Invite Code")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Type the 6-character code that the Estate Owner shared with you.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var codeEntryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(title: "Invite code",
                          systemImage: "character.textbox",
                          tint: .teal)

            VStack(alignment: .leading, spacing: 16) {
                TextField("ABC123", text: $code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .keyboardType(.asciiCapable)
                    .onChange(of: code) { _, newValue in
                        let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                        if filtered.count > 6 {
                            code = String(filtered.prefix(6)).uppercased()
                        } else {
                            code = filtered.uppercased()
                        }
                    }
                    .padding(.vertical, 22)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                codeIsComplete
                                    ? Color.teal.opacity(0.55)
                                    : Color(.separator).opacity(0.5),
                                lineWidth: 0.8
                            )
                    )

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Codes use letters and numbers only (no I, O, 0, or 1). Example: \(sampleCode)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: claimTapped) {
                    HStack(spacing: 8) {
                        if isClaiming {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isClaiming ? "Claiming…" : "Claim Executor Access")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(codeIsComplete && !isClaiming ? Color.teal : Color.gray.opacity(0.35))
                    )
                    .foregroundStyle(.white)
                }
                .disabled(!codeIsComplete || isClaiming)
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
    }

    private var backHint: some View {
        Button(action: onBack) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                Text("I don't have a code – go back")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Helpers

    private let sampleCode = "ABC789"

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

    // MARK: - Actions

    private func claimTapped() {
        let service = SupabaseVaultService.shared
        guard service.isConfigured else {
            errorMessage = "Invite codes require Family Prep cloud. Ask the Estate Owner for the code once the cloud vault is enabled."
            withAnimation(.default) { shakeTrigger.toggle() }
            return
        }
        Task {
            isClaiming = true
            defer { isClaiming = false }
            do {
                let estateID = try await service.claimExecutorInviteCode(code)
                onClaimed(estateID)
            } catch {
                errorMessage = error.localizedDescription
                withAnimation(.default) {
                    shakeTrigger.toggle()
                }
            }
        }
    }
}

// MARK: - Shake modifier for invalid code feedback

private struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

#Preview {
    InviteCodeClaimView(onBack: {}, onClaimed: { _ in })
}
