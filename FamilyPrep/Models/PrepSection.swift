import Foundation
import Observation

@Observable class PrepSection: Identifiable, Codable {
    var id: String
    var title: String
    var orderIndex: Int
    var isStandard: Bool
    var notes: String
    var youtubeURL: String
    var createdAt: Date
    var updatedAt: Date
    var checklistItems: [ChecklistItem]
    var attachments: [Attachment]

    init(id: String = UUID().uuidString,
         title: String,
         orderIndex: Int,
         isStandard: Bool = false,
         notes: String = "",
         youtubeURL: String = "",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         checklistItems: [ChecklistItem] = [],
         attachments: [Attachment] = []) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.isStandard = isStandard
        self.notes = notes
        self.youtubeURL = youtubeURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.checklistItems = checklistItems
        self.attachments = attachments
    }
}
