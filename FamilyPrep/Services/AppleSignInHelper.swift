import Foundation
import AuthenticationServices
import SwiftUI
import CryptoKit

@MainActor
final class AppleSignInCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    struct AppleCredential {
        let identityToken: String
        let nonce: String
        let email: String?
        let givenName: String?
        let familyName: String?
    }

    enum AuthError: LocalizedError {
        case noWindow
        case noIdentityToken
        case authorizationFailed(String)

        var errorDescription: String? {
            switch self {
            case .noWindow:
                return "Could not present the Sign in with Apple sheet. Try again."
            case .noIdentityToken:
                return "Apple did not return a valid identity token. Please try again."
            case .authorizationFailed(let msg):
                return "Sign in with Apple failed: \(msg)"
            }
        }
    }

    private var nonceState: String?
    private var continuation: CheckedContinuation<AppleCredential, Error>?

    func start() async throws -> AppleCredential {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let (raw, hashed) = Self.makeNonce()
        request.nonce = hashed
        nonceState = raw

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            controller.performRequests()
        }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        Task { @MainActor in
            _ = self
        }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? UIWindow()
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let cont = self.continuation else { return }
            defer {
                self.continuation = nil
                self.nonceState = nil
            }

            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                cont.resume(throwing: AuthError.authorizationFailed("Unexpected credential type."))
                return
            }

            guard let tokenData = appleCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = self.nonceState else {
                cont.resume(throwing: AuthError.noIdentityToken)
                return
            }

            let givenName = appleCredential.fullName?.givenName
            let familyName = appleCredential.fullName?.familyName
            let email = appleCredential.email

            let cred = AppleCredential(
                identityToken: tokenString,
                nonce: nonce,
                email: email,
                givenName: givenName,
                familyName: familyName
            )
            cont.resume(returning: cred)
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            guard let cont = self.continuation else { return }
            defer {
                self.continuation = nil
                self.nonceState = nil
            }
            let ns = error as NSError
            if ns.domain == ASAuthorizationError.errorDomain,
               ns.code == ASAuthorizationError.canceled.rawValue {
                cont.resume(throwing: AuthError.authorizationFailed("Sign in canceled by user."))
            } else {
                cont.resume(throwing: AuthError.authorizationFailed(error.localizedDescription))
            }
        }
    }

    private static func makeNonce() -> (raw: String, sha256: String) {
        let data = Data.randomBytes(count: 32)
        let raw = data.base64URLEncoded
        let digest = SHA256.hash(data: Data(raw.utf8))
        let hashed = Data(digest).base64URLEncoded
        return (raw, hashed)
    }
}

private extension Data {
    static func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

@MainActor
struct SignInWithAppleButton: View {
    enum LabelStyle {
        case standard
        case compact
    }

    let style: LabelStyle
    let action: () -> Void
    @State private var coordinator = AppleSignInCoordinator()

    init(style: LabelStyle = .standard, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.title2.weight(.semibold))
                switch style {
                case .standard:
                    Text("Continue with Apple")
                        .font(.headline)
                case .compact:
                    Text("Sign in with Apple")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, style == .standard ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: style == .standard ? 16 : 14, style: .continuous)
                    .fill(Color.black)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

@MainActor
func runAppleSignIn() async throws -> AppleSignInCoordinator.AppleCredential {
    let coordinator = AppleSignInCoordinator()
    return try await coordinator.start()
}
