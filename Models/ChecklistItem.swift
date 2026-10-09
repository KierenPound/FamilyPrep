import Foundation
import Observation

@Observable class ChecklistItem: Identifiable, Codable {
    var id: String
    var text: String
    var isCompleted: Bool
    var orderIndex: Int
    var createdAt: Date

    init(id: String = UUID().uuidString,
         text: String,
         isCompleted: Bool = false,
         orderIndex: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, text, isCompleted, orderIndex, createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        orderIndex = try c.decode(Int.self, forKey: .orderIndex)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encode(orderIndex, forKey: .orderIndex)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
