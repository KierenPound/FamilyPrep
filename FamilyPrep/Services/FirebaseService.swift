import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class FirebaseService {
    static let shared = FirebaseService()

    private(set) var isConfigured: Bool = false
    private var firestoreEnabled: Bool = false
    private var storageEnabled: Bool = false

    private init() {
        configureIfAvailable()
    }

    private func configureIfAvailable() {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
        FirebaseApp.configure()
        _ = Firestore.firestore()
        _ = Storage.storage()
        isConfigured = true
        firestoreEnabled = true
        storageEnabled = true
        print("✅ Firebase configured successfully")
        #else
        print("⚠️ Firebase SDK not installed. To enable cross-platform sync:")
        print("   1. Add Firestore & Storage via SPM: https://github.com/firebase/firebase-ios-sdk")
        print("   2. Download GoogleService-Info.plist into your project from Firebase Console")
        print("   3. The LocalDataRepository hooks (syncSectionToFirebase, etc.) are ready to wire.")
        #endif
    }

    // MARK: - Sections (Firestore: /sections/{sectionId})

    func upsertSection(_ section: PrepSection) async throws {
        guard firestoreEnabled else { return }
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "id": section.id,
            "title": section.title,
            "orderIndex": section.orderIndex,
            "isStandard": section.isStandard,
            "notes": section.notes,
            "youtubeURL": section.youtubeURL,
            "createdAt": Timestamp(date: section.createdAt),
            "updatedAt": Timestamp(date: section.updatedAt),
            "checklistItems": section.checklistItems.map { item in
                [
                    "id": item.id,
                    "text": item.text,
                    "isCompleted": item.isCompleted,
                    "orderIndex": item.orderIndex,
                    "createdAt": Timestamp(date: item.createdAt)
                ]
            }
        ]
        try await db.collection("sections").document(section.id).setData(data, merge: true)
        #endif
    }

    func deleteSection(sectionId: String) async throws {
        guard firestoreEnabled else { return }
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        try await db.collection("sections").document(sectionId).delete()
        #endif
    }

    func observeSections(handler: @escaping @Sendable ([PrepSection]) -> Void) {
        guard firestoreEnabled else { return }
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        db.collection("sections")
            .order(by: "orderIndex", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    if let error = error { print("🔥 Firestore observe error: \(error)") }
                    return
                }
                let sections: [PrepSection] = docs.compactMap { doc in
                    let data = doc.data()
                    let id = data["id"] as? String ?? doc.documentID
                    let title = data["title"] as? String ?? ""
                    let orderIndex = data["orderIndex"] as? Int ?? 0
                    let isStandard = data["isStandard"] as? Bool ?? false
                    let notes = data["notes"] as? String ?? ""
                    let youtubeURL = data["youtubeURL"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    let section = PrepSection(
                        id: id,
                        title: title,
                        orderIndex: orderIndex,
                        isStandard: isStandard,
                        notes: notes,
                        youtubeURL: youtubeURL,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                    if let rawItems = data["checklistItems"] as? [[String: Any]] {
                        for raw in rawItems {
                            let ci = ChecklistItem(
                                id: raw["id"] as? String ?? UUID().uuidString,
                                text: raw["text"] as? String ?? "",
                                isCompleted: raw["isCompleted"] as? Bool ?? false,
                                orderIndex: raw["orderIndex"] as? Int ?? 0,
                                createdAt: (raw["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            )
                            section.checklistItems.append(ci)
                        }
                    }
                    return section
                }
                Task { @MainActor in handler(sections) }
            }
        #endif
    }

    // MARK: - Attachments (Firebase Storage: /attachments/{sectionId}/{fileName})

    func uploadAttachment(data: Data,
                          sectionId: String,
                          fileName: String,
                          contentType: String) async throws -> (downloadURL: String, storagePath: String) {
        guard storageEnabled else {
            throw NSError(domain: "Firebase", code: 501, userInfo: [
                NSLocalizedDescriptionKey: "Firebase Storage not configured. Add SDK & GoogleService-Info.plist"
            ])
        }
        #if canImport(FirebaseStorage)
        let storage = Storage.storage()
        let path = "attachments/\(sectionId)/\(fileName)"
        let ref = storage.reference().child(path)
        let meta = StorageMetadata()
        meta.contentType = contentType
        let _ = try await ref.putDataAsync(data, metadata: meta)
        let url = try await ref.downloadURL()
        return (url.absoluteString, path)
        #else
        throw NSError(domain: "Firebase", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "FirebaseStorage module not available. Add the Firebase iOS SDK (FirebaseStorage) via SPM or CocoaPods."
        ])
        #endif
    }

    func deleteAttachment(storagePath: String) async throws {
        guard storageEnabled else { return }
        #if canImport(FirebaseStorage)
        let storage = Storage.storage()
        let ref = storage.reference().child(storagePath)
        try await ref.delete()
        #endif
    }
}
