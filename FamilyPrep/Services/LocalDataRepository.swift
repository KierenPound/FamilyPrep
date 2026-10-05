import Foundation
import Combine
import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@MainActor
class LocalDataRepository: DataRepositoryProtocol, ObservableObject {
    @Published var sections: [PrepSection] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let persistenceFileName = "familyprep_sections.json"

    init() {
        _ = FirebaseService.shared
    }

    private var persistenceFileURL: URL {
        let fm = FileManager.default
        let docs = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return docs.appendingPathComponent(persistenceFileName)
    }

    // MARK: - Persistence

    private func loadFromDisk() throws -> [PrepSection] {
        let url = persistenceFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PrepSection].self, from: data)
    }

    private func saveToDisk() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sections)
        try data.write(to: persistenceFileURL, options: [.atomic])
    }

    // MARK: - Load / Seed

    func loadSections() async throws {
        isLoading = true
        defer { isLoading = false }

        let saved = try loadFromDisk()
        if saved.isEmpty {
            try seedStandardSections()
        } else {
            sections = saved
            try ensureStandardSectionsPresent()
        }
    }

    private func ensureStandardSectionsPresent() throws {
        let standards = Self.standardTitlesBlueprint
        let existingTitles = Set(sections.map { $0.title })
        var didChange = false
        for item in standards {
            guard !existingTitles.contains(item.title) else { continue }
            let nextOrder = (sections.map { $0.orderIndex }.max() ?? -1) + 1
            let section = PrepSection(
                title: item.title,
                orderIndex: nextOrder,
                isStandard: true,
                youtubeURL: item.youtube,
                createdAt: Date(),
                updatedAt: Date()
            )
            for (itemIndex, text) in item.sampleItems.enumerated() {
                section.checklistItems.append(
                    ChecklistItem(text: text, isCompleted: false, orderIndex: itemIndex)
                )
            }
            sections.append(section)
            didChange = true
            Task { try? await syncSectionToFirebase(section) }
        }
        if didChange {
            sections.sort { $0.orderIndex < $1.orderIndex }
            try saveToDisk()
        }
    }

    private static let standardTitlesBlueprint: [(title: String, youtube: String, sampleItems: [String])] = [
        ("What to Do First", "https://www.youtube.com/embed/b4ZypVnbYHM?playsinline=1", [
            "Notify immediate family members",
            "Locate important documents folder",
            "Contact family attorney if available",
            "Secure the home and vehicles",
            "Gather financial account information"
        ]),
        ("Legal Documents", "https://youtu.be/AL8chWFuM-s", [
            "Last Will and Testament",
            "Power of Attorney (Financial)",
            "Power of Attorney (Medical)",
            "Living Will / Advance Directive",
            "Trust documents",
            "Property deeds and titles"
        ]),
        ("Who to Notify", "https://youtu.be/tuyBCSYTs5A", [
            "Submit batch notification via Life Ledger portal",
            "Contact TSB — Main + Kieren Retirement + House Funds + Savings accounts",
            "Contact Starling Bank — Kieren and Bren accounts",
            "Notify Tembo (ISAs) via their bereavement guide",
            "Claim NS&I Premium Bonds (Holder Number 30905977E)",
            "Notify West Midlands Pension Authority (Mum's Pension)",
            "Call @SIPP on 0141 204 7950 re: Monkton building",
            "Notify Lifesight / Willis Towers Watson (Dad's Pension)",
            "Cancel or transfer Octopus Energy (both properties)",
            "Cancel Sky broadband, TV, stream and mobile (both addresses)",
            "Cancel direct-debit digital subscriptions",
            "Secure and log in to all Mac computers (password: birth town)"
        ]),
        ("Running the Houses", "", [
            "Mortgage or rent payments",
            "Utilities: electric, gas, water, internet",
            "Home insurance",
            "Property taxes",
            "Security alarm monitoring",
            "Gardening and pool maintenance",
            "HOA dues"
        ]),
        ("Funeral Arrangements", "", [
            "Contact funeral home",
            "Choose burial or cremation",
            "Select cemetery plot if applicable",
            "Plan memorial service",
            "Write obituary",
            "Arrange flowers",
            "Organize catering for wake",
            "Notify clergy or celebrant"
        ]),
        ("Cars", "", [
            "Locate vehicle titles",
            "Car insurance policies",
            "Registration documents",
            "Loan or lease payoff info",
            "Spare keys location",
            "List of mechanics or service centers"
        ]),
        ("Confirmation", "", [
            "Death certificate ordered (10+ copies)",
            "Social Security notified",
            "Employer notified",
            "Banks and accounts closed",
            "Insurance claims filed",
            "Credit bureaus notified",
            "Postal mail forwarding set",
            "All final debts settled"
        ]),
        ("Kieren's Jukebox", "", [])
    ]

    private func seedStandardSections() throws {
        let standardTitles = Self.standardTitlesBlueprint

        var seeded: [PrepSection] = []
        for (index, item) in standardTitles.enumerated() {
            let section = PrepSection(
                title: item.title,
                orderIndex: index,
                isStandard: true,
                youtubeURL: item.youtube,
                createdAt: Date(),
                updatedAt: Date()
            )

            for (itemIndex, text) in item.sampleItems.enumerated() {
                let checklistItem = ChecklistItem(
                    text: text,
                    isCompleted: false,
                    orderIndex: itemIndex
                )
                section.checklistItems.append(checklistItem)
            }

            seeded.append(section)
        }

        sections = seeded
        try saveToDisk()
    }

    // MARK: - Sections CRUD

    func addSection(title: String) async throws -> PrepSection {
        let nextOrder = (sections.map { $0.orderIndex }.max() ?? -1) + 1
        let section = PrepSection(
            title: title,
            orderIndex: nextOrder,
            isStandard: false
        )
        sections.append(section)
        sections.sort { $0.orderIndex < $1.orderIndex }
        try saveToDisk()
        try await syncSectionToFirebase(section)
        return section
    }

    func deleteSection(_ section: PrepSection) async throws {
        for attachment in section.attachments {
            try? deleteAttachmentFile(at: attachment.storagePath)
        }
        sections.removeAll { $0.id == section.id }
        try saveToDisk()
        try await deleteSectionFromFirebase(section)
    }

    func updateSection(_ section: PrepSection) async throws {
        section.updatedAt = Date()
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            sections[index] = section
        }
        try saveToDisk()
        try await syncSectionToFirebase(section)
    }

    // MARK: - Checklist Items

    func addChecklistItem(to section: PrepSection, text: String) async throws {
        let nextOrder = (section.checklistItems.map { $0.orderIndex }.max() ?? -1) + 1
        let item = ChecklistItem(text: text, orderIndex: nextOrder)
        section.checklistItems.append(item)
        section.updatedAt = Date()
        if let sectionIndex = sections.firstIndex(where: { $0.id == section.id }) {
            sections[sectionIndex] = section
        }
        try saveToDisk()
        try await syncSectionToFirebase(section)
    }

    func toggleChecklistItem(_ item: ChecklistItem) async throws {
        item.isCompleted.toggle()
        if let sectionIndex = sections.firstIndex(where: { $0.checklistItems.contains(where: { $0.id == item.id }) }) {
            let section = sections[sectionIndex]
            section.updatedAt = Date()
            sections[sectionIndex] = section
            try saveToDisk()
            try await syncSectionToFirebase(section)
        }
    }

    func setChecklistItem(_ item: ChecklistItem, isCompleted: Bool) async throws {
        item.isCompleted = isCompleted
        if let sectionIndex = sections.firstIndex(where: { $0.checklistItems.contains(where: { $0.id == item.id }) }) {
            let section = sections[sectionIndex]
            section.updatedAt = Date()
            sections[sectionIndex] = section
            try saveToDisk()
            try await syncSectionToFirebase(section)
        }
    }

    func deleteChecklistItem(_ item: ChecklistItem, from section: PrepSection) async throws {
        section.checklistItems.removeAll { $0.id == item.id }
        section.updatedAt = Date()
        if let sectionIndex = sections.firstIndex(where: { $0.id == section.id }) {
            sections[sectionIndex] = section
        }
        try saveToDisk()
        try await syncSectionToFirebase(section)
    }

    // MARK: - Attachments

    func uploadPhoto(_ photo: PhotosPickerItem, to section: PrepSection) async throws -> Attachment {
        isLoading = true
        defer { isLoading = false }

        guard let data = try await photo.loadTransferable(type: Data.self) else {
            throw NSError(domain: "DataRepo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load photo data"])
        }

        let ext = (photo.supportedContentTypes.first?.preferredFilenameExtension) ?? "jpg"
        let utType = photo.supportedContentTypes.first ?? .jpeg
        var fileName: String
        if let original = photo.itemIdentifier {
            fileName = "\(UUID().uuidString)_\(original).\(ext)"
        } else {
            fileName = "\(UUID().uuidString).\(ext)"
        }
        let displayName = photo.itemIdentifier ?? "Photo.\(ext)"
        _ = utType
        let attachment = Attachment(
            fileName: displayName,
            type: .photo,
            storagePath: "attachments/\(section.id)/\(fileName)",
            downloadURL: "",
            fileSize: Int64(data.count)
        )

        try saveAttachmentToDocuments(data: data, fileName: fileName, sectionId: section.id)
        let docURL = try documentsFileURL(fileName: fileName, sectionId: section.id)
        attachment.downloadURL = docURL.absoluteString
        attachment.storagePath = docURL.absoluteString

        section.attachments.append(attachment)
        section.updatedAt = Date()
        try saveToDisk()
        try await syncAttachmentToFirebase(attachment: attachment, data: data, section: section)
        return attachment
    }

    func uploadPDF(at url: URL, to section: PrepSection) async throws -> Attachment {
        isLoading = true
        defer { isLoading = false }

        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer { if shouldStopAccessing { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let fileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
        let attachment = Attachment(
            fileName: url.lastPathComponent,
            type: .pdf,
            storagePath: "attachments/\(section.id)/\(fileName)",
            downloadURL: "",
            fileSize: Int64(data.count)
        )

        try saveAttachmentToDocuments(data: data, fileName: fileName, sectionId: section.id)
        let docURL = try documentsFileURL(fileName: fileName, sectionId: section.id)
        attachment.downloadURL = docURL.absoluteString
        attachment.storagePath = docURL.absoluteString

        section.attachments.append(attachment)
        section.updatedAt = Date()
        try saveToDisk()
        try await syncAttachmentToFirebase(attachment: attachment, data: data, section: section)
        return attachment
    }

    func uploadFile(at url: URL, to section: PrepSection) async throws -> Attachment {
        isLoading = true
        defer { isLoading = false }

        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer { if shouldStopAccessing { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let ext = url.pathExtension.lowercased()
        let type: AttachmentType
        if ext == "pdf" {
            type = .pdf
        } else if ["png", "jpg", "jpeg", "heic", "gif", "tiff", "bmp", "webp"].contains(ext) {
            type = .photo
        } else {
            type = .unknown
        }

        let storageName = "\(UUID().uuidString)_\(url.lastPathComponent)"
        let attachment = Attachment(
            fileName: url.lastPathComponent,
            type: type,
            storagePath: "attachments/\(section.id)/\(storageName)",
            downloadURL: "",
            fileSize: Int64(data.count)
        )

        try saveAttachmentToDocuments(data: data, fileName: storageName, sectionId: section.id)
        let docURL = try documentsFileURL(fileName: storageName, sectionId: section.id)
        attachment.downloadURL = docURL.absoluteString
        attachment.storagePath = docURL.absoluteString

        section.attachments.append(attachment)
        section.updatedAt = Date()
        try saveToDisk()
        try await syncAttachmentToFirebase(attachment: attachment, data: data, section: section)
        return attachment
    }

    func deleteAttachment(_ attachment: Attachment, from section: PrepSection) async throws {
        section.attachments.removeAll { $0.id == attachment.id }
        try? deleteAttachmentFile(at: attachment.storagePath)
        section.updatedAt = Date()
        try saveToDisk()
        try await deleteAttachmentFromFirebase(attachment)
    }

    // MARK: - Attachment File Helpers

    private func documentsFileURL(fileName: String, sectionId: String) throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let sectionDir = docs.appendingPathComponent("attachments", isDirectory: true)
            .appendingPathComponent(sectionId, isDirectory: true)
        if !fm.fileExists(atPath: sectionDir.path) {
            try fm.createDirectory(at: sectionDir, withIntermediateDirectories: true)
        }
        return sectionDir.appendingPathComponent(fileName)
    }

    private func saveAttachmentToDocuments(data: Data, fileName: String, sectionId: String) throws {
        let url = try documentsFileURL(fileName: fileName, sectionId: sectionId)
        try data.write(to: url, options: [.atomic])
    }

    private func deleteAttachmentFile(at storagePath: String) throws {
        if let url = URL(string: storagePath), url.isFileURL {
            try FileManager.default.removeItem(at: url)
            return
        }
        // Try as relative path from docs
        let fm = FileManager.default
        if let docs = try? fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let full = docs.appendingPathComponent(storagePath)
            if fm.fileExists(atPath: full.path) {
                try fm.removeItem(at: full)
            }
        }
    }

    // MARK: - Firebase Sync

    private func syncSectionToFirebase(_ section: PrepSection) async throws {
        try await FirebaseService.shared.upsertSection(section)
    }

    private func deleteSectionFromFirebase(_ section: PrepSection) async throws {
        for attachment in section.attachments {
            try await deleteAttachmentFromFirebase(attachment)
        }
        try await FirebaseService.shared.deleteSection(sectionId: section.id)
    }

    private func syncAttachmentToFirebase(attachment: Attachment, data: Data, section: PrepSection) async throws {
        let contentType = mimeType(for: attachment.type)
        let storageFileName = extractStorageFileName(from: attachment)

        do {
            let result = try await FirebaseService.shared.uploadAttachment(
                data: data,
                sectionId: section.id,
                fileName: storageFileName,
                contentType: contentType
            )
            attachment.downloadURL = result.downloadURL
            attachment.storagePath = result.storagePath
            section.updatedAt = Date()
            try saveToDisk()
            try await FirebaseService.shared.upsertSection(section)
        } catch {
            print("⚠️ Firebase attachment upload skipped: \(error.localizedDescription)")
        }
    }

    private func deleteAttachmentFromFirebase(_ attachment: Attachment) async throws {
        try await FirebaseService.shared.deleteAttachment(storagePath: attachment.storagePath)
    }

    private func mimeType(for type: AttachmentType) -> String {
        switch type {
        case .photo:
            return "image/jpeg"
        case .pdf:
            return "application/pdf"
        case .unknown:
            return "application/octet-stream"
        }
    }

    private func extractStorageFileName(from attachment: Attachment) -> String {
        if attachment.storagePath.contains("attachments/") {
            if let range = attachment.storagePath.range(of: "attachments/") {
                let relative = String(attachment.storagePath[range.upperBound...])
                if let slashIndex = relative.firstIndex(of: "/") {
                    let afterSection = relative.index(after: slashIndex)
                    return String(relative[afterSection...])
                }
            }
        }
        if let url = URL(string: attachment.storagePath) {
            return "\(UUID().uuidString)_\(url.lastPathComponent)"
        }
        return "\(UUID().uuidString)_\(attachment.fileName)"
    }
}
