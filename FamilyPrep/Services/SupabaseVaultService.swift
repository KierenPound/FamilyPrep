//
//  SupabaseVaultService.swift
//  FamilyPrep
//
//  Cloud vault service backed by Supabase Postgres + private Storage bucket.
//
//  SPM INSTALLATION (if not already present):
//    1. In Xcode, open FamilyPrep.xcodeproj
//    2. Select the "FamilyPrep" project (blue icon) in the Project Navigator →
//       choose the "FamilyPrep" iOS target → "Package Dependencies" tab
//    3. Click the "+" button under "Package Dependencies"
//    4. Paste this URL into the search/input field:
//       https://github.com/supabase-community/supabase-swift
//    5. Set Dependency Rule to "Up to Next Major Version" → minimum: 2.0.0
//    6. In the "Add to Target" column next to the "Supabase" product,
//       ensure "FamilyPrep" is selected
//    7. Click "Add Package" and wait for Xcode to resolve
//
//  INFO.PLIST CONFIGURATION (recommended; inline fallback used if absent):
//    Add two rows to FamilyPrep/Info.plist (or the Info tab of the target):
//      • Key: "SUPABASE_URL"       Type: String  Value: <your Supabase project URL>
//      • Key: "SUPABASE_ANON_KEY"  Type: String  Value: <anon key, NOT service_role>
//    NEVER commit the service_role key to source control.
//

import Foundation

// MARK: - VaultDocument (file-local value type)

struct VaultDocument: Identifiable, Decodable, Sendable {
    let id: UUID
    let estateID: UUID
    let title: String
    let storagePath: String
    let category: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case estateID = "estate_id"
        case title
        case storagePath = "storage_path"
        case category
        case createdAt = "created_at"
    }
}

struct EstateRecord: Identifiable, Decodable, Sendable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case createdAt = "created_at"
    }
}

struct EstateAccessRecord: Identifiable, Decodable, Sendable {
    let id: UUID
    let estateID: UUID
    let userID: UUID?
    let role: String
    let status: String?
    let invitedEmail: String?
    let inviteCode: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case estateID = "estate_id"
        case userID = "user_id"
        case role
        case status
        case invitedEmail = "invited_email"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

struct ExecutorInvite: Sendable {
    let inviteCode: String
    let invitedEmail: String
    let estateID: UUID
}

// MARK: - EstateRole

enum EstateRole: String, Sendable {
    case owner
    case executor
}

// MARK: - SupabaseVaultService

@MainActor
final class SupabaseVaultService {
    static let shared = SupabaseVaultService()

    private(set) var isConfigured: Bool = false
    private(set) var isAuthenticated: Bool = false

    #if canImport(Supabase)
    private var supabase: SupabaseClient?
    #endif

    private let bucketID = "estate-documents"

    private init() {
        configureIfAvailable()
    }

    // MARK: - Configuration

    func configure() {
        configureIfAvailable()
    }

    private func configureIfAvailable() {
        #if canImport(Supabase)
        do {
            let (url, anonKey) = try resolveCredentials()
            supabase = SupabaseClient(
                supabaseURL: url,
                supabaseKey: anonKey
            )
            isConfigured = true
            Task { await refreshAuthState() }
            print("✅ SupabaseVaultService configured successfully")
        } catch {
            isConfigured = false
            print("⚠️ SupabaseVaultService not configured: \(error.localizedDescription). "
                  + "Add supabase-swift SPM package and set SUPABASE_URL + SUPABASE_ANON_KEY.")
        }
        #else
        isConfigured = false
        print("⚠️ Supabase SDK not installed. To enable the cloud vault:")
        print("   1. Add supabase-swift via SPM: https://github.com/supabase-community/supabase-swift")
        print("   2. Configure SUPABASE_URL + SUPABASE_ANON_KEY in Info.plist (see file header)")
        print("   3. The method signatures and VaultDocument type are already declared and stubbed below.")
        #endif
    }

    #if canImport(Supabase)
    private func resolveCredentials() throws -> (url: URL, anonKey: String) {
        let bundle = Bundle.main
        let plistURL = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let plistKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        let fallbackURL = "https://mpsygpgaakdtlgjzmbtr.supabase.co"
        let fallbackKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wc3lncGdhYWtkdGxnanptYnRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyOTY4NDIsImV4cCI6MjEwNjg3Mjg0Mn0.KUYfeNM_3tNW-H3ftSgdfHvJAtbPbI95-M077nNFq-U"

        let rawURL = (plistURL?.isEmpty == false) ? plistURL! : fallbackURL
        let anonKey = (plistKey?.isEmpty == false) ? plistKey! : fallbackKey

        guard let url = URL(string: rawURL) else {
            throw NSError(
                domain: "SupabaseVault",
                code: 501,
                userInfo: [NSLocalizedDescriptionKey: "Invalid SUPABASE_URL: \(rawURL)"]
            )
        }
        return (url, anonKey)
    }

    private func refreshAuthState() async {
        guard let supabase = supabase else { return }
        do {
            let session = try await supabase.auth.session
            isAuthenticated = (session.user.id as? UUID) != nil
        } catch {
            isAuthenticated = false
        }
    }

    // MARK: - Private helpers — estate lifecycle

    private func currentUserID() async throws -> UUID {
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }
        let session = try await supabase.auth.session
        guard let uid = session.user.id as? UUID else {
            throw NSError(
                domain: "SupabaseVault",
                code: 201,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user session"]
            )
        }
        return uid
    }

    private func ensureDefaultOwnerEstate(name: String = "My Estate") async throws -> UUID {
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        struct EstateRow: Decodable {
            let id: UUID
        }

        do {
            let existing: [EstateRow] = try await supabase
                .from("estates")
                .select("id")
                .order("created_at", ascending: true)
                .limit(1)
                .execute()
                .value

            if let first = existing.first {
                return first.id
            }
        } catch {
            try throwTransformed(error: error, operation: "ensureDefaultOwnerEstate.select")
        }

        let ownerID = try await currentUserID()
        let newEstateID = UUID()
        do {
            _ = try await supabase
                .from("estates")
                .insert([
                    "id": newEstateID.uuidString,
                    "owner_id": ownerID.uuidString,
                    "name": name
                ])
                .execute()
        } catch {
            try throwTransformed(error: error, operation: "ensureDefaultOwnerEstate.insert.estate")
        }

        do {
            _ = try await supabase
                .from("estate_access")
                .insert([
                    "estate_id": newEstateID.uuidString,
                    "user_id": ownerID.uuidString,
                    "role": EstateRole.owner.rawValue,
                    "status": "accepted"
                ])
                .execute()
        } catch {
            try throwTransformed(error: error, operation: "ensureDefaultOwnerEstate.insert.access")
        }

        return newEstateID
    }

    private func randomInviteCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
    #endif

    // MARK: - Public API

    /// Upload a document's Data to the private `estate-documents` bucket and
    /// insert a matching row into the `documents` table.
    ///
    /// - Parameters:
    ///   - data: Raw file bytes (PDF, image, text, etc.).
    ///   - fileName: Display filename preserved in the storage path.
    ///   - contentType: MIME type (e.g. `application/pdf`, `image/jpeg`).
    ///   - estateID: Target estate; `nil` auto-creates/fetches the owner's default estate.
    ///   - title: Human-readable document title stored in the DB row.
    ///   - category: Free-form category (e.g. "Will", "Deed", "ID").
    /// - Returns: `(documentID, storagePath)` — storagePath is bucket-relative
    ///   (`{estate_id}/{document_id}/{fileName}`) for use with `signedURL(for:)`.
    func uploadDocument(
        data: Data,
        fileName: String,
        contentType: String,
        estateID: UUID? = nil,
        title: String,
        category: String
    ) async throws -> (documentID: UUID, storagePath: String) {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        let resolvedEstateID: UUID
        if let provided = estateID {
            resolvedEstateID = provided
        } else {
            resolvedEstateID = try await ensureDefaultOwnerEstate()
        }

        let documentID = UUID()
        let safeFileName = fileName.isEmpty ? "document" : fileName
        let objectPath = "\(resolvedEstateID.uuidString)/\(documentID.uuidString)/\(safeFileName)"

        do {
            let fileOptions = FileOptions(
                cacheControl: "3600",
                contentType: contentType,
                upsert: false
            )
            _ = try await supabase.storage
                .from(bucketID)
                .upload(
                    path: objectPath,
                    data: data,
                    options: fileOptions
                )
        } catch {
            try throwTransformed(error: error, operation: "uploadDocument.storage.upload")
        }

        struct InsertDoc: Encodable {
            let id: String
            let estateId: String
            let title: String
            let storagePath: String
            let category: String

            enum CodingKeys: String, CodingKey {
                case id
                case estateId = "estate_id"
                case title
                case storagePath = "storage_path"
                case category
            }
        }

        do {
            _ = try await supabase
                .from("documents")
                .insert(
                    InsertDoc(
                        id: documentID.uuidString,
                        estateId: resolvedEstateID.uuidString,
                        title: title,
                        storagePath: objectPath,
                        category: category
                    )
                )
                .execute()
        } catch {
            try throwTransformed(error: error, operation: "uploadDocument.db.insert")
        }

        return (documentID, objectPath)
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Fetch every document row visible to the currently authenticated user
    /// (Owner → all docs for owned estates; Executor → read-only docs for
    /// estates they are linked to; RLS enforces the scoping server-side).
    func fetchMyVaultItems() async throws -> [VaultDocument] {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        do {
            let response = try await supabase
                .from("documents")
                .select()
                .order("created_at", ascending: false)
                .execute()
            return response.value
        } catch {
            try throwTransformed(error: error, operation: "fetchMyVaultItems.select")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Request a short-lived signed URL for a private bucket object so the
    /// file can be viewed in-app (PDFKit, WKWebView, etc.) without a
    /// permanent public link.
    ///
    /// - Parameters:
    ///   - storagePath: Bucket-relative path as returned from `uploadDocument`
    ///     (i.e. `{estate_id}/{document_id}/{fileName}`).
    ///   - expiresIn: Window in seconds before the URL signature expires
    ///     (default 1 hour).
    func signedURL(for storagePath: String, expiresIn: TimeInterval = 3600) async throws -> URL {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        do {
            let result = try await supabase.storage
                .from(bucketID)
                .createSignedURL(path: storagePath, expiresIn: Int(expiresIn))
            if let url = result as? URL {
                return url
            }
            if let response = result as? (signedURL: URL, token: String) {
                return response.signedURL
            }
            let mirror = Mirror(reflecting: result)
            for child in mirror.children {
                if let url = child.value as? URL {
                    return url
                }
            }
            throw NSError(
                domain: "SupabaseVault",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "createSignedURL returned unexpected type \(type(of: result))"]
            )
        } catch {
            try throwTransformed(error: error, operation: "signedURL.createSignedURL")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    // MARK: - Onboarding Public API

    /// Resolve the current user's linked estate and role.
    /// Returns `(estateID, role)` or `nil` if the user has no accepted link
    /// (i.e. no estate ownership AND no accepted executor invite).
    func resolveCurrentUserEstateAndRole() async throws -> (estateID: UUID, role: EstateRole)? {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        do {
            let accessRows: [EstateAccessRecord] = try await supabase
                .from("estate_access")
                .select()
                .eq("status", value: "accepted")
                .order("created_at", ascending: true)
                .execute()
                .value

            var ownerMatch: EstateAccessRecord?
            var executorMatch: EstateAccessRecord?
            for row in accessRows {
                guard row.userID != nil else { continue }
                if row.role == EstateRole.owner.rawValue { ownerMatch = row }
                else if row.role == EstateRole.executor.rawValue { executorMatch = row }
            }

            if let owner = ownerMatch, owner.userID != nil {
                return (owner.estateID, .owner)
            }
            if let exec = executorMatch {
                return (exec.estateID, .executor)
            }
            return nil
        } catch {
            try throwTransformed(error: error, operation: "resolveCurrentUserEstateAndRole.select")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Create the default "My Estate" record for the current authenticated
    /// user and mark them as the Owner in estate_access. Returns the new
    /// estate's ID. Idempotent: if an owner estate already exists it is
    /// returned unchanged.
    @discardableResult
    func createDefaultOwnerEstate(name: String = "My Estate") async throws -> UUID {
        #if canImport(Supabase)
        return try await ensureDefaultOwnerEstate(name: name)
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Claim a pending executor invite code on behalf of the currently
    /// authenticated user. Updates the matching estate_access row:
    /// `user_id = auth.uid()`, `status = 'accepted'`.
    ///
    /// - Returns: The `estateID` the user is now linked to as an executor.
    @discardableResult
    func claimExecutorInviteCode(_ rawCode: String) async throws -> UUID {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        let trimmedCode = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard trimmedCode.count == 6 else {
            throw NSError(
                domain: "SupabaseVault",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "Invite code must be 6 characters."]
            )
        }

        let uid = try await currentUserID()

        struct UpdateClaim: Encodable {
            let userID: String
            let status: String
            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case status
            }
        }

        do {
            let updated: [EstateAccessRecord] = try await supabase
                .from("estate_access")
                .update(UpdateClaim(userID: uid.uuidString, status: "accepted"))
                .eq("invite_code", value: trimmedCode)
                .eq("status", value: "pending")
                .is("user_id", value: nil as Any?)
                .eq("role", value: EstateRole.executor.rawValue)
                .select()
                .execute()
                .value

            guard let claimed = updated.first else {
                throw NSError(
                    domain: "SupabaseVault",
                    code: 100,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid or already claimed invite code."]
                )
            }
            return claimed.estateID
        } catch let ns as NSError where ns.domain == "SupabaseVault" {
            throw ns
        } catch {
            try throwTransformed(error: error, operation: "claimExecutorInviteCode.update")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Generate a unique 6-character invite code for an executor, insert a
    /// pending estate_access row, and return the code + email pair so the UI
    /// can let the owner copy/share it.
    ///
    /// - Parameters:
    ///   - estateID: The owner's estate (must be currently owned by caller).
    ///   - email: Executor's email address (stored for the owner's records).
    func generateExecutorInvite(estateID: UUID, email: String) async throws -> ExecutorInvite {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedEmail.isEmpty else {
            throw NSError(
                domain: "SupabaseVault",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "Executor email is required."]
            )
        }

        struct InsertPending: Encodable {
            let estateID: String
            let role: String
            let status: String
            let invitedEmail: String
            let inviteCode: String

            enum CodingKeys: String, CodingKey {
                case estateID = "estate_id"
                case role
                case status
                case invitedEmail = "invited_email"
                case inviteCode = "invite_code"
            }
        }

        let maxAttempts = 10
        for _ in 0..<maxAttempts {
            let code = randomInviteCode(length: 6)
            do {
                _ = try await supabase
                    .from("estate_access")
                    .insert(
                        InsertPending(
                            estateID: estateID.uuidString,
                            role: EstateRole.executor.rawValue,
                            status: "pending",
                            invitedEmail: normalizedEmail,
                            inviteCode: code
                        )
                    )
                    .execute()
                return ExecutorInvite(inviteCode: code, invitedEmail: normalizedEmail, estateID: estateID)
            } catch {
                let ns = error as NSError
                let msg = ns.localizedDescription.lowercased()
                let isUnique = msg.contains("invite_code_unique")
                    || msg.contains("unique_pending_email")
                    || msg.contains("duplicate key")
                    || msg.contains("23505")
                if !isUnique {
                    try throwTransformed(error: error, operation: "generateExecutorInvite.insert")
                }
                continue
            }
        }

        throw NSError(
            domain: "SupabaseVault",
            code: 100,
            userInfo: [NSLocalizedDescriptionKey: "Failed to generate a unique invite code. Please try again."]
        )
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Return current user account details (email + display name) for the
    /// welcome view, if the session is active and Supabase is configured.
    func currentUserProfile() async -> (email: String?, displayName: String?) {
        #if canImport(Supabase)
        guard let supabase = supabase else { return (nil, nil) }
        do {
            let session = try await supabase.auth.session
            let user = session.user
            return (user.email, user.userMetadata?["name"] as? String ?? user.email)
        } catch {
            return (nil, nil)
        }
        #else
        return (nil, nil)
        #endif
    }

    // MARK: - Settings / Estate Management Public API

    /// Fetch all executor access rows (pending + accepted + revoked) for the
    /// given estate. Only an Owner can read full estate_access rows for their
    /// estate via RLS.
    func fetchExecutors(for estateID: UUID) async throws -> [EstateAccessRecord] {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }
        do {
            let rows: [EstateAccessRecord] = try await supabase
                .from("estate_access")
                .select()
                .eq("estate_id", value: estateID.uuidString)
                .eq("role", value: EstateRole.executor.rawValue)
                .order("created_at", ascending: true)
                .execute()
                .value
            return rows
        } catch {
            try throwTransformed(error: error, operation: "fetchExecutors.select")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Revoke an executor's access by deleting their estate_access row.
    /// For pending invites (user_id NULL) this simply removes the pending row.
    /// For accepted executors this deletes the accepted link; RLS enforces
    /// that the caller must be the Owner of the estate.
    func revokeExecutorAccess(_ accessRecordID: UUID) async throws {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }
        do {
            _ = try await supabase
                .from("estate_access")
                .delete()
                .eq("id", value: accessRecordID.uuidString)
                .execute()
        } catch {
            try throwTransformed(error: error, operation: "revokeExecutorAccess.delete")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Delete ALL storage objects under the estate's prefix in the
    /// `estate-documents` bucket, then delete the estate row (cascades to
    /// estate_access and documents), and finally sign out the user.
    /// Caller MUST be the owner. Owner-only RLS is enforced server-side.
    func deleteEstateAndAllData(estateID: UUID) async throws {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }

        let prefix = "\(estateID.uuidString)/"
        do {
            let paths = try await supabase.storage
                .from(bucketID)
                .list(path: prefix)
            if !paths.isEmpty {
                let objectPaths = paths.map { prefix + ($0.name ?? "") }
                _ = try await supabase.storage
                    .from(bucketID)
                    .remove(paths: objectPaths)
            }
        } catch {
            try throwTransformed(error: error, operation: "deleteEstateAndAllData.storage.remove")
        }

        do {
            _ = try await supabase
                .from("estates")
                .delete()
                .eq("id", value: estateID.uuidString)
                .execute()
        } catch {
            try throwTransformed(error: error, operation: "deleteEstateAndAllData.estates.delete")
        }

        do {
            try await supabase.auth.signOut()
        } catch {
            try throwTransformed(error: error, operation: "deleteEstateAndAllData.auth.signOut")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    /// Sign the user out of the Supabase session. Does not delete any data.
    func signOut() async throws {
        #if canImport(Supabase)
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }
        do {
            try await supabase.auth.signOut()
        } catch {
            try throwTransformed(error: error, operation: "signOut")
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    // MARK: - Error helpers

    private func makeNotConfiguredError() -> Error {
        NSError(
            domain: "SupabaseVault",
            code: 501,
            userInfo: [
                NSLocalizedDescriptionKey: """
                SupabaseVaultService is not configured.
                • Add the supabase-swift SPM package (see header instructions).
                • Set SUPABASE_URL + SUPABASE_ANON_KEY in Info.plist.
                • Call SupabaseVaultService.shared.configure() after sign-in.
                """
            ]
        )
    }

    #if canImport(Supabase)
    private func throwTransformed(error: Error, operation: String) throws -> Never {
        let ns = error as NSError
        let code = ns.code
        let httpStatus = (ns.userInfo["statusCode"] as? Int)
            ?? (ns.userInfo["http_status"] as? Int)
            ?? 0

        let mappedCode: Int
        switch (code, httpStatus) {
        case (_, 401), (_, 403), (_, 406):
            mappedCode = 200 + httpStatus
        case (_, 400...499):
            mappedCode = 140
        case (_, 500...599):
            mappedCode = 150
        case (-1009), (-1005), (-1004), (-1001):
            mappedCode = 110
        default:
            mappedCode = 100
        }

        let rawMsg = ns.localizedDescription
        let message = """
        SupabaseVault.\(operation) failed (\(mappedCode)): \(rawMsg)
        """

        throw NSError(
            domain: "SupabaseVault",
            code: mappedCode,
            userInfo: [
                NSLocalizedDescriptionKey: message,
                NSUnderlyingErrorKey: error
            ]
        )
    }
    #endif
}
