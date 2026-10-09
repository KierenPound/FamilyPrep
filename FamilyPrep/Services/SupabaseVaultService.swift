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
//  NOTES ON supabase-swift 2.x POSTGREST ARCHITECTURE (2.55.3):
//    • select/insert/update/delete ALL live on PostgrestQueryBuilder.
//    • They return a PostgrestFilterBuilder for filter chaining.
//    • insert(_:) and update(_:) throw (they encode values eagerly).
//    • delete() does NOT throw.
//    • execute() lives on the PostgrestBuilder base class:
//        func execute() async throws -> PostgrestResponse<Void>              // discard body
//        func execute<T: Decodable>() async throws -> PostgrestResponse<T>   // typed decode
//    • PostgrestFilterBuilder inherits from PostgrestTransformBuilder,
//      which re-exposes select() returning PostgrestTransformBuilder.
//    • eq/order/limit/is take `any PostgrestFilterValue` — Swift 5.9 allows
//      passing a literal; cast to the protocol existential to unify overloads.
//

import Foundation

#if canImport(Supabase)
import Supabase
#endif
#if canImport(PostgREST)
import PostgREST
#endif
#if canImport(Storage)
import Storage
#endif
#if canImport(Auth)
import Auth
#endif
#if canImport(Functions)
import Functions
#endif
#if canImport(Realtime)
import Realtime
#endif

// MARK: - Domain models (compiled even without SDK)

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

enum EstateRole: String, Sendable {
    case owner
    case executor
}

#if canImport(PostgREST)

// MARK: - JSON wrappers
//
// Supabase's insert/update use generic `<T: Encodable>`. To pass dynamic
// `[String: Any]` payloads, we wrap them in concrete types that encode
// themselves directly.

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { Int(stringValue) }
    init?(intValue: Int) { self.init(stringValue: "\(intValue)") }
}

private struct AnyDictionary: Encodable, @unchecked Sendable {
    let value: [String: Any]
    init(_ value: [String: Any]) { self.value = value }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyCodingKey.self)
        for (k, v) in value {
            let key = AnyCodingKey(stringValue: k)!
            switch v {
            case let s as String: try c.encode(s, forKey: key)
            case let i as Int: try c.encode(i, forKey: key)
            case let i64 as Int64: try c.encode(i64, forKey: key)
            case let b as Bool: try c.encode(b, forKey: key)
            case let d as Double: try c.encode(d, forKey: key)
            case let u as UUID: try c.encode(u.uuidString, forKey: key)
            case let d as Date: try c.encode(d, forKey: key)
            case let u as URL: try c.encode(u.absoluteString, forKey: key)
            case is NSNull: try c.encodeNil(forKey: key)
            case let o as Any? where o == nil: try c.encodeNil(forKey: key)
            case let arr as [Any]: try c.encode(AnyArray(arr), forKey: key)
            case let dict as [String: Any]: try c.encode(AnyDictionary(dict), forKey: key)
            default: try c.encode(String(describing: v), forKey: key)
            }
        }
    }
}

private struct AnyArray: Encodable, @unchecked Sendable {
    let items: [Any]
    init(_ items: [Any]) { self.items = items }

    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        for v in items {
            switch v {
            case let s as String: try c.encode(s)
            case let i as Int: try c.encode(i)
            case let i64 as Int64: try c.encode(i64)
            case let b as Bool: try c.encode(b)
            case let d as Double: try c.encode(d)
            case let u as UUID: try c.encode(u.uuidString)
            case let d as Date: try c.encode(d)
            case let u as URL: try c.encode(u.absoluteString)
            case is NSNull: try c.encodeNil()
            case let o as Any? where o == nil: try c.encodeNil()
            case let arr as [Any]: try c.encode(AnyArray(arr))
            case let dict as [String: Any]: try c.encode(AnyDictionary(dict))
            default: try c.encode(String(describing: v))
            }
        }
    }
}
#endif

// MARK: - SupabaseVaultService

@MainActor
final class SupabaseVaultService {
    static let shared = SupabaseVaultService()

    private(set) var isConfigured: Bool = false
    private(set) var isAuthenticated: Bool = false

    #if canImport(Supabase)
    private typealias _SBClient = SupabaseClient
    private var supabase: _SBClient?
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
            supabase = _SBClient(
                supabaseURL: url,
                supabaseKey: anonKey
            )
            isConfigured = true
            Task { await refreshAuthState() }
            NSLog("FamilyPrepVault %@", "✅ SupabaseVaultService configured successfully")
        } catch {
            isConfigured = false
            NSLog("FamilyPrepVault %@", "⚠️ SupabaseVaultService not configured: \(error.localizedDescription). "
                  + "Add supabase-swift SPM package and set SUPABASE_URL + SUPABASE_ANON_KEY.")
        }
        #else
        isConfigured = false
        NSLog("FamilyPrepVault %@", "⚠️ Supabase SDK not installed. To enable the cloud vault:")
        NSLog("FamilyPrepVault %@", "   1. Add supabase-swift via SPM: https://github.com/supabase-community/supabase-swift")
        NSLog("FamilyPrepVault %@", "   2. Configure SUPABASE_URL + SUPABASE_ANON_KEY in Info.plist (see file header)")
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
    #endif

    // MARK: - Value extraction bridge (Mirror-based)

    #if canImport(Supabase)
    private enum Bridge {
        static func userMetadataDictionary(_ anyValue: Any) -> [String: Any] {
            if let dict = anyValue as? [String: Any] { return dict }
            let mirror = Mirror(reflecting: anyValue)
            if mirror.displayStyle == .dictionary {
                var result: [String: Any] = [:]
                for child in mirror.children {
                    guard let label = child.label else { continue }
                    let elMirror = Mirror(reflecting: child.value)
                    var keyAny: Any?
                    var valAny: Any?
                    for e in elMirror.children {
                        if e.label == "0" { keyAny = e.value }
                        else if e.label == "1" { valAny = e.value }
                    }
                    if let k = keyAny as? String { result[k] = valAny }
                    else { result[label] = child.value }
                }
                return result
            }
            if mirror.displayStyle == .struct || mirror.displayStyle == .class {
                for child in mirror.children {
                    switch child.label {
                    case "anyValue", "value", "objectValue", "dictionaryValue":
                        return userMetadataDictionary(child.value)
                    default: continue
                    }
                }
            }
            return [:]
        }

        static func fileNames(from storageList: Any) -> [String] {
            guard let arr = storageList as? [Any] else { return [] }
            return arr.compactMap { item in
                let m = Mirror(reflecting: item)
                for c in m.children {
                    if c.label == "name", let s = c.value as? String { return s }
                }
                return nil
            }
        }

        static func url(from storageResult: Any) -> URL? {
            if let u = storageResult as? URL { return u }
            let mirror = Mirror(reflecting: storageResult)
            for child in mirror.children {
                if let u = child.value as? URL { return u }
            }
            return nil
        }
    }

    private enum BridgeError: LocalizedError {
        case missing(String)

        var errorDescription: String? {
            switch self {
            case .missing(let s):
                return "SupabaseBridge: missing runtime symbol \(s). Verify supabase-swift 2.x is linked."
            }
        }
    }

    // MARK: - Postgrest builder helpers
    //
    // Rule: insert/update/delete are only available on PostgrestQueryBuilder
    // and throw. Filter methods live on PostgrestFilterBuilder. `select` and
    // `execute` exist on both (via inheritance or re-export). We never
    // extend SDK types — that caused infinite recursion and shadowing
    // errors earlier. All dispatch happens HERE in SupabaseVaultService.

    private func table(_ name: String) throws -> PostgrestQueryBuilder {
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }
        return supabase.from(name)
    }

    @discardableResult
    private func select(_ qb: PostgrestQueryBuilder, columns: String = "*") -> PostgrestFilterBuilder {
        qb.select(columns)
    }

    @discardableResult
    private func insert(_ qb: PostgrestQueryBuilder, _ payload: Any) throws -> PostgrestFilterBuilder {
        if let d = payload as? [String: Any] {
            return try qb.insert(AnyDictionary(d))
        }
        return try qb.insert(AnyDictionary([:]))
    }

    @discardableResult
    private func update(_ qb: PostgrestQueryBuilder, _ payload: Any) throws -> PostgrestFilterBuilder {
        if let d = payload as? [String: Any] {
            return try qb.update(AnyDictionary(d))
        }
        return try qb.update(AnyDictionary([:]))
    }

    @discardableResult
    private func delete(_ qb: PostgrestQueryBuilder) -> PostgrestFilterBuilder {
        qb.delete()
    }

    // Filter helpers operate on a PostgrestFilterBuilder and return it for
    // fluent chaining through our opaque `var builder = …` local Any pattern.

    @discardableResult
    private func filter(
        _ fb: PostgrestFilterBuilder,
        method: String,
        column: String,
        value: Any?
    ) -> PostgrestFilterBuilder {
        switch method {
        case "eq":
            if let v = value {
                switch v {
                case let s as String: return fb.eq(column, value: s)
                case let i as Int: return fb.eq(column, value: i)
                case let b as Bool: return fb.eq(column, value: b)
                case let u as UUID: return fb.eq(column, value: u.uuidString)
                default: return fb.eq(column, value: String(describing: v))
                }
            }
            return fb.`is`(column, value: nil as Bool?)
        case "isNull":
            return fb.`is`(column, value: nil as Bool?)
        default:
            return fb
        }
    }

    @discardableResult
    private func order(_ fb: PostgrestFilterBuilder, column: String, ascending: Bool) -> PostgrestFilterBuilder {
        fb.order(column, ascending: ascending) as! PostgrestFilterBuilder
    }

    @discardableResult
    private func limit(_ fb: PostgrestFilterBuilder, _ n: Int) -> PostgrestFilterBuilder {
        fb.limit(n) as! PostgrestFilterBuilder
    }

    /// Executes with the Void-return overload (no decoding) — good for mutations.
    @discardableResult
    private func executeVoid(_ builder: PostgrestFilterBuilder) async throws -> Any {
        try await builder.execute()
    }

    /// Executes a SELECT-style query and decodes rows as `[T]`. Also works for
    /// UPDATE/DELETE when `returning: .representation` is set (the SDK
    /// default). The typed `<[T]>` overload is selected by the explicit
    /// local-var type annotation on the response.
    private func executeDecoded<T: Decodable>(_ builder: PostgrestFilterBuilder, as _: T.Type) async throws -> [T] {
        do {
            let response: PostgrestResponse<[T]> = try await builder.execute()
            return response.value
        } catch {
            throw error
        }
    }
    #endif

    #if canImport(Supabase) && canImport(Storage)
    // MARK: - Storage shortcuts

    private func storageBucket(_ name: String) throws -> StorageFileApi {
        guard let supabase = supabase else {
            throw makeNotConfiguredError()
        }
        return supabase.storage.from(name)
    }

    private func storageUpload(
        bucket: StorageFileApi,
        path: String,
        data: Data
    ) async throws {
        do {
            _ = try await bucket.upload(path, data: data)
        } catch {
            throw error
        }
    }

    private func storageCreateSignedURL(
        bucket: StorageFileApi,
        path: String,
        expiresIn: Int
    ) async throws -> URL {
        do {
            let res = try await bucket.createSignedURL(path: path, expiresIn: expiresIn)
            if let u = Bridge.url(from: res) { return u }
            throw BridgeError.missing("createSignedURL result.url")
        } catch {
            throw error
        }
    }

    private func storageList(
        bucket: StorageFileApi,
        prefix: String
    ) async throws -> [String] {
        do {
            let res = try await bucket.list(path: prefix)
            return Bridge.fileNames(from: res)
        } catch {
            throw error
        }
    }

    private func storageRemove(
        bucket: StorageFileApi,
        paths: [String]
    ) async throws {
        guard !paths.isEmpty else { return }
        do {
            _ = try await bucket.remove(paths: paths)
        } catch {
            throw error
        }
    }
    #endif

    // MARK: - Auth helpers

    #if canImport(Supabase)
    private func refreshAuthState() async {
        guard let supabase = supabase else { return }
        do {
            let session = try await supabase.auth.session
            guard !session.isExpired else { isAuthenticated = false; return }
            let idValue: Any = session.user.id
            switch idValue {
            case is UUID: isAuthenticated = true
            case let str as String: isAuthenticated = UUID(uuidString: str) != nil
            default: isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
    }

    private func currentUserIDOptional() async -> UUID? {
        guard let supabase = supabase else { return nil }
        do {
            let session = try await supabase.auth.session
            guard !session.isExpired else { return nil }
            let idValue: Any = session.user.id
            switch idValue {
            case let uuid as UUID: return uuid
            case let str as String:
                guard let uuid = UUID(uuidString: str) else { fallthrough }
                return uuid
            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func currentUserID() async throws -> UUID {
        guard let id = await currentUserIDOptional() else {
            throw NSError(domain: "SupabaseVault", code: 201,
                          userInfo: [NSLocalizedDescriptionKey: "Please sign in to link your identity to this vault action."])
        }
        return id
    }

    private func currentUserFromSession() async throws -> (email: String?, displayName: String?) {
        guard let supabase = supabase else { return (nil, nil) }
        do {
            let session = try await supabase.auth.session
            guard !session.isExpired else { return (nil, nil) }
            let user = session.user
            let email = user.email
            let meta = Bridge.userMetadataDictionary(user.userMetadata)
            return (email, (meta["name"] as? String) ?? email)
        } catch {
            return (nil, nil)
        }
    }
    #endif

    // MARK: - Estate lifecycle

    #if canImport(Supabase)
    private func ensureDefaultOwnerEstate(
        name: String = "My Estate",
        preferredID: UUID? = nil
    ) async throws -> UUID {
        guard supabase != nil else {
            throw makeNotConfiguredError()
        }

        struct EstateRow: Decodable, Identifiable {
            let id: UUID
        }

        let ownerID = await currentUserIDOptional()

        // If the caller already has a local ID they want to keep, try to find an
        // authenticated owner row first, otherwise fall back to the shared
        // "most recent" lookup for backwards compatibility.
        if let preferred = preferredID, ownerID != nil {
            do {
                let q = try table("estates")
                var fb = select(q, columns: "id, owner_id")
                fb = filter(fb, method: "eq", column: "id", value: preferred.uuidString as Any?)
                let rows: [EstateRow] = try await executeDecoded(fb, as: EstateRow.self)
                if !rows.isEmpty {
                    try await ensureOwnerBackingRows(estateID: preferred, ownerID: ownerID!)
                    return preferred
                }
            } catch { /* fall through to create path */ }
        }

        let q = try table("estates")
        let selected = select(q, columns: "id")
        let ordered = order(selected, column: "created_at", ascending: true)
        let limited = limit(ordered, 1)

        let existingIDs: [EstateRow]
        do {
            existingIDs = try await executeDecoded(limited, as: EstateRow.self)
        } catch {
            existingIDs = []
        }
        if let first = existingIDs.first {
            if let o = ownerID {
                try await ensureOwnerBackingRows(estateID: first.id, ownerID: o)
            }
            return first.id
        }

        let newEstateID = preferredID ?? UUID()

        var estatePayload: [String: Any] = [
            "id": newEstateID.uuidString,
            "name": name
        ]
        if let o = ownerID { estatePayload["owner_id"] = o.uuidString }

        do {
            let estateQ = try table("estates")
            let estateFb = try insert(estateQ, estatePayload)
            _ = try await executeVoid(estateFb)
        } catch {
            throw error
        }

        if let o = ownerID {
            try await ensureOwnerBackingRows(estateID: newEstateID, ownerID: o)
        }

        return newEstateID
    }

    private func ensureOwnerBackingRows(estateID: UUID, ownerID: UUID) async throws {
        guard let supabase = supabase else { throw makeNotConfiguredError() }

        struct SimpleID: Decodable, Identifiable { let id: UUID }

        do {
            NSLog("FamilyPrepVault %@", "👤 [ensureOwnerBackingRows] estate=\(estateID.uuidString) owner=\(ownerID.uuidString) — checking estates row…")
            let estatesQ = try table("estates")
            var estatesFB = select(estatesQ, columns: "id, owner_id")
            estatesFB = filter(estatesFB, method: "eq", column: "id", value: estateID.uuidString as Any?)
            let estatesRows: [SimpleID] = try await executeDecoded(estatesFB, as: SimpleID.self)

            if estatesRows.isEmpty {
                NSLog("FamilyPrepVault %@", "👤 → no estates row found; INSERTING estates (id + owner_id)…")
                let payload: [String: Any] = [
                    "id": estateID.uuidString,
                    "owner_id": ownerID.uuidString,
                    "name": "My Estate"
                ]
                let insertQ = try table("estates")
                let insertFB = try insert(insertQ, payload)
                _ = try await executeVoid(insertFB)
                NSLog("FamilyPrepVault %@", "👤 ✅ estates INSERT ok")
            } else {
                NSLog("FamilyPrepVault %@", "👤 → estates row found; UPDATING owner_id=\(ownerID.uuidString)…")
                let updatePayload: [String: Any] = [
                    "owner_id": ownerID.uuidString
                ]
                let updateQ = try table("estates")
                var updateFB = try update(updateQ, updatePayload)
                updateFB = filter(updateFB, method: "eq", column: "id", value: estateID.uuidString as Any?)
                _ = try await executeVoid(updateFB)
                NSLog("FamilyPrepVault %@", "👤 ✅ estates UPDATE ok")
            }
        } catch {
            let ns = error as NSError
            NSLog("FamilyPrepVault %@", "👤 ⚠️ estates stage error: code=\(ns.code) msg=\(ns.localizedDescription)")
            if !ns.localizedDescription.lowercased().contains("duplicate key")
                && !ns.localizedDescription.lowercased().contains("23505") {
                throw error
            }
            NSLog("FamilyPrepVault %@", "👤 → (duplicate key → safe to ignore)")
        }

        do {
            NSLog("FamilyPrepVault %@", "👤 [ensureOwnerBackingRows] estate=\(estateID.uuidString) — checking owner access row…")
            let accessQ = try table("estate_access")
            var accessFB = select(accessQ, columns: "id")
            accessFB = filter(accessFB, method: "eq", column: "estate_id", value: estateID.uuidString as Any?)
            accessFB = filter(accessFB, method: "eq", column: "role", value: EstateRole.owner.rawValue as Any?)
            accessFB = filter(accessFB, method: "eq", column: "user_id", value: ownerID.uuidString as Any?)
            let existing: [SimpleID] = try await executeDecoded(accessFB, as: SimpleID.self)
            guard existing.isEmpty else {
                NSLog("FamilyPrepVault %@", "👤 ✅ owner access row already present — nothing to do")
                return
            }

            NSLog("FamilyPrepVault %@", "👤 → no owner access row; INSERTING estate_access (owner/accepted)…")
            let payload: [String: Any] = [
                "estate_id": estateID.uuidString,
                "user_id": ownerID.uuidString,
                "role": EstateRole.owner.rawValue,
                "status": "accepted"
            ]
            let insertQ = try table("estate_access")
            let insertFB = try insert(insertQ, payload)
            _ = try await executeVoid(insertFB)
            NSLog("FamilyPrepVault %@", "👤 ✅ owner estate_access INSERT ok")
        } catch {
            let ns = error as NSError
            let msg = ns.localizedDescription.lowercased()
            NSLog("FamilyPrepVault %@", "👤 ⚠️ access stage error: code=\(ns.code) msg=\(ns.localizedDescription)")
            if msg.contains("duplicate key") || msg.contains("23505")
                || msg.contains("unique_user_per_estate") {
                NSLog("FamilyPrepVault %@", "👤 → (duplicate/unique → safe to ignore)")
                return
            }
            throw error
        }
    }

    private func randomInviteCode(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
    #endif

    // MARK: - Public API

    func uploadDocument(
        data: Data,
        fileName: String,
        contentType: String,
        estateID: UUID? = nil,
        title: String,
        category: String
    ) async throws -> (documentID: UUID, storagePath: String) {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        let resolvedEstateID: UUID
        if let provided = estateID { resolvedEstateID = provided }
        else { resolvedEstateID = try await ensureDefaultOwnerEstate() }

        let documentID = UUID()
        let safeFileName = fileName.isEmpty ? "document" : fileName
        let objectPath = "\(resolvedEstateID.uuidString)/\(documentID.uuidString)/\(safeFileName)"

        #if canImport(Storage)
        do {
            let bucket = try storageBucket(bucketID)
            try await storageUpload(bucket: bucket, path: objectPath, data: data)
        } catch {
            throw error
        }
        #endif

        let payload: [String: Any] = [
            "id": documentID.uuidString,
            "estate_id": resolvedEstateID.uuidString,
            "title": title,
            "storage_path": objectPath,
            "category": category
        ]
        do {
            let qb = try table("documents")
            let fb = try insert(qb, payload)
            _ = try await executeVoid(fb)
        } catch {
            throw error
        }

        return (documentID, objectPath)
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func fetchMyVaultItems() async throws -> [VaultDocument] {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        do {
            let qb = try table("documents")
            let selected = select(qb)
            let ordered = order(selected, column: "created_at", ascending: false)
            return try await executeDecoded(ordered, as: VaultDocument.self)
        } catch {
            throw error
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func signedURL(for storagePath: String, expiresIn: TimeInterval = 3600) async throws -> URL {
        #if canImport(Supabase) && canImport(Storage)
        guard supabase != nil else { throw makeNotConfiguredError() }
        do {
            let bucket = try storageBucket(bucketID)
            return try await storageCreateSignedURL(bucket: bucket, path: storagePath, expiresIn: Int(expiresIn))
        } catch {
            throw error
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    // MARK: - Onboarding Public API

    func resolveCurrentUserEstateAndRole() async throws -> (estateID: UUID, role: EstateRole)? {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }

        // If user has no session yet, they can't have a resolved role.
        // Return nil without hitting the network (and likely failing RLS anyway).
        guard await currentUserIDOptional() != nil else { return nil }

        do {
            let qb = try table("estate_access")
            var fb = select(qb)
            fb = filter(fb, method: "eq", column: "status", value: "accepted" as Any?)
            fb = order(fb, column: "created_at", ascending: true)
            let rows: [EstateAccessRecord] = try await executeDecoded(fb, as: EstateAccessRecord.self)

            var ownerMatch: EstateAccessRecord?
            var executorMatch: EstateAccessRecord?
            for row in rows {
                guard row.userID != nil else { continue }
                if row.role == EstateRole.owner.rawValue { ownerMatch = row }
                else if row.role == EstateRole.executor.rawValue { executorMatch = row }
            }

            if let owner = ownerMatch, owner.userID != nil { return (owner.estateID, .owner) }
            if let exec = executorMatch { return (exec.estateID, .executor) }
            return nil
        } catch {
            throw error
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    @discardableResult
    func createDefaultOwnerEstate(
        name: String = "My Estate",
        preferredID: UUID? = nil
    ) async throws -> UUID {
        #if canImport(Supabase)
        return try await ensureDefaultOwnerEstate(name: name, preferredID: preferredID)
        #else
        throw makeNotConfiguredError()
        #endif
    }

    @discardableResult
    func ensureOwnerCloudBacking(estateID: UUID, name: String = "My Estate") async throws -> UUID {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        let uid = try await currentUserID()
        try await ensureOwnerBackingRows(estateID: estateID, ownerID: uid)
        return estateID
        #else
        throw makeNotConfiguredError()
        #endif
    }

    @discardableResult
    func claimExecutorInviteCode(_ rawCode: String) async throws -> UUID {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        let uid = try await currentUserID()
        let trimmedCode = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmedCode.count == 6 else {
            throw NSError(domain: "SupabaseVault", code: 100,
                          userInfo: [NSLocalizedDescriptionKey: "Invite code must be 6 characters."])
        }
        do {
            let payload: [String: Any] = [
                "user_id": uid.uuidString,
                "status": "accepted"
            ]
            let qb = try table("estate_access")
            var fb = try update(qb, payload)
            fb = filter(fb, method: "eq", column: "invite_code", value: trimmedCode as Any?)
            fb = filter(fb, method: "eq", column: "status", value: "pending" as Any?)
            fb = filter(fb, method: "isNull", column: "user_id", value: nil)
            fb = filter(fb, method: "eq", column: "role", value: EstateRole.executor.rawValue as Any?)
            let updated: [EstateAccessRecord] = try await executeDecoded(fb, as: EstateAccessRecord.self)
            guard let claimed = updated.first else {
                throw NSError(domain: "SupabaseVault", code: 100,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid or already claimed invite code."])
            }
            return claimed.estateID
        } catch {
            throw error
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func generateExecutorInvite(estateID: UUID, email: String) async throws -> ExecutorInvite {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        guard let ownerID = await currentUserIDOptional() else {
            NSLog("FamilyPrepVault %@", "🔒 [generateExecutorInvite] ❌ no authenticated Supabase session — skipping DB call")
            throw NSError(domain: "SupabaseVault", code: 202,
                          userInfo: [
                            NSLocalizedDescriptionKey: """
                            Sign in required to send executor invites.
                            Invite codes link your cloud identity as the estate owner.
                            You can skip this step and return later after signing in.
                            """
                          ])
        }
        NSLog("FamilyPrepVault %@", "🔒 [generateExecutorInvite] session ownerID = \(ownerID.uuidString)")
        NSLog("FamilyPrepVault %@", "🔒 → estateID from AppState = \(estateID.uuidString)")
        NSLog("FamilyPrepVault %@", "🔒 → isAuthenticated = \(isAuthenticated)")

        do {
            NSLog("FamilyPrepVault %@", "🔒 → PREFLIGHT: SELECT * FROM estate_access WHERE user_id = ownerID (check auth.link works)")
            let pfQB1 = try table("estate_access")
            var pfFB1 = select(pfQB1, columns: "id, estate_id, role, status, user_id")
            pfFB1 = filter(pfFB1, method: "eq", column: "user_id", value: ownerID.uuidString as Any?)
            pfFB1 = filter(pfFB1, method: "eq", column: "status", value: "accepted" as Any?)
            let pfRows1: [EstateAccessRecord] = try await executeDecoded(pfFB1, as: EstateAccessRecord.self)
            NSLog("FamilyPrepVault %@", "🔒 → preflight user-owned rows: \(pfRows1.count) rows → \(pfRows1.map { "\($0.role):\($0.estateID.uuidString.prefix(8))" }.joined(separator: ", "))")

            NSLog("FamilyPrepVault %@", "🔒 → PREFLIGHT: SELECT * FROM estates WHERE id = AppState.estateID (check RLS on estates)")
            struct EstateDiag: Decodable, Identifiable {
                let id: UUID
                enum CodingKeys: String, CodingKey { case id }
            }
            let pfQB2 = try table("estates")
            var pfFB2 = select(pfQB2, columns: "id, owner_id, name")
            pfFB2 = filter(pfFB2, method: "eq", column: "id", value: estateID.uuidString as Any?)
            let pfRows2: [EstateDiag] = try await executeDecoded(pfFB2, as: EstateDiag.self)
            NSLog("FamilyPrepVault %@", "🔒 → preflight AppState-estate row: \(pfRows2.count) rows")

            if pfRows2.isEmpty && pfRows1.isEmpty {
                NSLog("FamilyPrepVault %@", "🔒 ⚠️ NO matching estates or estate_access rows for this user — onboarding fallback path, will try to INSERT backing rows now")
            } else if !pfRows1.isEmpty {
                if !pfRows1.contains(where: { $0.estateID == estateID }) {
                    NSLog("FamilyPrepVault %@", "🔒 ⚠️ AppState's estateID \(estateID.uuidString.prefix(8)) NOT in user's accepted estates → backing-rows insert is required")
                }
            }
        } catch {
            let ns = error as NSError
            NSLog("FamilyPrepVault %@", "🔒 ⚠️ PREFLIGHT failed with code=\(ns.code) msg=\(ns.localizedDescription). RLS/network is broken at the SELECT layer.")
        }

        do {
            try await ensureOwnerBackingRows(estateID: estateID, ownerID: ownerID)
            NSLog("FamilyPrepVault %@", "🔒 ✅ ensureOwnerBackingRows completed")
        } catch {
            let ns = error as NSError
            NSLog("FamilyPrepVault %@", "🔒 ❌ ensureOwnerBackingRows FAILED: code=\(ns.code) msg=\(ns.localizedDescription)")
            throw ns
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            throw NSError(domain: "SupabaseVault", code: 100,
                          userInfo: [NSLocalizedDescriptionKey: "Executor email is required."])
        }
        let maxAttempts = 10
        for attempt in 0..<maxAttempts {
            let code = randomInviteCode(length: 6)
            let payload: [String: Any] = [
                "estate_id": estateID.uuidString,
                "role": EstateRole.executor.rawValue,
                "status": "pending",
                "invited_email": normalizedEmail,
                "invite_code": code
            ]
            do {
                let qb = try table("estate_access")
                let fb = try insert(qb, payload)
                _ = try await executeVoid(fb)
                NSLog("FamilyPrepVault %@", "🔒 ✅ invite INSERT OK on attempt \(attempt+1): code=\(code)")
                return ExecutorInvite(inviteCode: code, invitedEmail: normalizedEmail, estateID: estateID)
            } catch {
                let ns = error as NSError
                let msg = ns.localizedDescription.lowercased()
                NSLog("FamilyPrepVault %@", "🔒 invite INSERT attempt \(attempt+1) error: code=\(ns.code) msg=\(ns.localizedDescription)")
                let isUnique = msg.contains("invite_code_unique")
                    || msg.contains("unique_pending_email")
                    || msg.contains("duplicate key")
                    || msg.contains("23505")
                if isUnique { continue }
                if msg.contains("permission denied") || msg.contains("row level security")
                    || msg.contains("policy") || msg.contains("estate_access")
                    || ns.code == 403 || msg.contains("42501") {
                    throw NSError(domain: "SupabaseVault", code: 203,
                                  userInfo: [
                                    NSLocalizedDescriptionKey: """
                                    Your estate isn't fully linked in Supabase yet.
                                    Please re-run the onboarding flow (or sign out and back in).
                                    If the problem persists, open Supabase → SQL Editor and run the
                                    file supabase/migrations/ensure_estate_rls_and_grants.sql again,
                                    then check the auth.users table contains your signed-in account.
                                    """
                                  ])
                }
                throw error
            }
        }
        throw NSError(domain: "SupabaseVault", code: 100,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to generate a unique invite code. Please try again."])
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func currentUserProfile() async -> (email: String?, displayName: String?) {
        #if canImport(Supabase)
        guard supabase != nil else { return (nil, nil) }
        do {
            return try await currentUserFromSession()
        } catch {
            return (nil, nil)
        }
        #else
        return (nil, nil)
        #endif
    }

    // MARK: - Settings / Estate Management

    func fetchExecutors(for estateID: UUID) async throws -> [EstateAccessRecord] {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        do {
            let qb = try table("estate_access")
            var fb = select(qb)
            fb = filter(fb, method: "eq", column: "estate_id", value: estateID.uuidString as Any?)
            fb = filter(fb, method: "eq", column: "role", value: EstateRole.executor.rawValue as Any?)
            fb = order(fb, column: "created_at", ascending: true)
            return try await executeDecoded(fb, as: EstateAccessRecord.self)
        } catch {
            throw error
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func revokeExecutorAccess(_ accessRecordID: UUID) async throws {
        #if canImport(Supabase)
        guard supabase != nil else { throw makeNotConfiguredError() }
        do {
            let qb = try table("estate_access")
            var fb = delete(qb)
            fb = filter(fb, method: "eq", column: "id", value: accessRecordID.uuidString as Any?)
            _ = try await executeVoid(fb)
        } catch {
            throw error
        }
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func deleteEstateAndAllData(estateID: UUID) async throws {
        #if canImport(Supabase)
        guard let supabase = supabase else { throw makeNotConfiguredError() }
        let prefix = "\(estateID.uuidString)/"

        #if canImport(Storage)
        do {
            let bucket = try storageBucket(bucketID)
            let names = try await storageList(bucket: bucket, prefix: prefix)
            if !names.isEmpty {
                let paths = names.map { prefix + $0 }
                try await storageRemove(bucket: bucket, paths: paths)
            }
        } catch {
            throw error
        }
        #endif

        do {
            let estateQ = try table("estates")
            var estateFb = delete(estateQ)
            estateFb = filter(estateFb, method: "eq", column: "id", value: estateID.uuidString as Any?)
            _ = try await executeVoid(estateFb)
        } catch {
            throw error
        }

        try await supabase.auth.signOut()
        #else
        throw makeNotConfiguredError()
        #endif
    }

    func signOut() async throws {
        #if canImport(Supabase)
        guard let supabase = supabase else { throw makeNotConfiguredError() }
        try await supabase.auth.signOut()
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
        switch code {
        case -1009, -1005, -1004, -1001:
            mappedCode = 110
        default:
            switch httpStatus {
            case 401, 403, 406:
                mappedCode = 200 + httpStatus
            case 400...499:
                mappedCode = 140
            case 500...599:
                mappedCode = 150
            default:
                mappedCode = 100
            }
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

// End of file
