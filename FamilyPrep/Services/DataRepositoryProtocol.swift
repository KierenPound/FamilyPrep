import Foundation
import Combine
import PhotosUI
import SwiftUI
import UIKit

protocol DataRepositoryProtocol: ObservableObject {
    var sections: [PrepSection] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func loadSections() async throws
    func addSection(title: String) async throws -> PrepSection
    func deleteSection(_ section: PrepSection) async throws
    func updateSection(_ section: PrepSection) async throws

    func addChecklistItem(to section: PrepSection, text: String) async throws
    func toggleChecklistItem(_ item: ChecklistItem) async throws
    func setChecklistItem(_ item: ChecklistItem, isCompleted: Bool) async throws
    func deleteChecklistItem(_ item: ChecklistItem, from section: PrepSection) async throws

    func uploadPhoto(_ photo: PhotosPickerItem, to section: PrepSection) async throws -> Attachment
    func uploadPDF(at url: URL, to section: PrepSection) async throws -> Attachment
    func uploadFile(at url: URL, to section: PrepSection) async throws -> Attachment
    func deleteAttachment(_ attachment: Attachment, from section: PrepSection) async throws
}
