import Foundation
import Observation

enum AttachmentType: String, Codable {
    case photo
    case pdf
    case unknown
}

@Observable class Attachment: Identifiable, Codable {
    var id: String
    var fileName: String
    var type: AttachmentType
    var storagePath: String
    var downloadURL: String
    var fileSize: Int64
    var createdAt: Date

    init(id: String = UUID().uuidString,
         fileName: String,
         type: AttachmentType = .unknown,
         storagePath: String = "",
         downloadURL: String = "",
         fileSize: Int64 = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.fileName = fileName
        self.type = type
        self.storagePath = storagePath
        self.downloadURL = downloadURL
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
}
