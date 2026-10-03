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
}
