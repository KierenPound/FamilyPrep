import Foundation
import Observation

enum AttachmentType: String, Codable, Sendable {
    case photo
    case pdf
    case unknown
}

@Observable class Attachment: Identifiable, Codable, @unchecked Sendable {
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

    enum CodingKeys: String, CodingKey {
        case id, fileName, type, storagePath, downloadURL, fileSize, createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        fileName = try c.decode(String.self, forKey: .fileName)
        type = try c.decode(AttachmentType.self, forKey: .type)
        storagePath = try c.decode(String.self, forKey: .storagePath)
        downloadURL = try c.decode(String.self, forKey: .downloadURL)
        fileSize = try c.decode(Int64.self, forKey: .fileSize)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(type, forKey: .type)
        try c.encode(storagePath, forKey: .storagePath)
        try c.encode(downloadURL, forKey: .downloadURL)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
