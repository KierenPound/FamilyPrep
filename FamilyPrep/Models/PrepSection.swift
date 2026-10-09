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

    enum CodingKeys: String, CodingKey {
        case id, title, orderIndex, isStandard, notes, youtubeURL, createdAt, updatedAt, checklistItems, attachments
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        orderIndex = try c.decode(Int.self, forKey: .orderIndex)
        isStandard = try c.decode(Bool.self, forKey: .isStandard)
        notes = try c.decode(String.self, forKey: .notes)
        youtubeURL = try c.decode(String.self, forKey: .youtubeURL)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        checklistItems = try c.decode([ChecklistItem].self, forKey: .checklistItems)
        attachments = try c.decode([Attachment].self, forKey: .attachments)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(orderIndex, forKey: .orderIndex)
        try c.encode(isStandard, forKey: .isStandard)
        try c.encode(notes, forKey: .notes)
        try c.encode(youtubeURL, forKey: .youtubeURL)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(checklistItems, forKey: .checklistItems)
        try c.encode(attachments, forKey: .attachments)
    }
}
