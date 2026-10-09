import Foundation
import UIKit

struct JukeboxTrack: Identifiable, Hashable {
    let id: String
    let title: String
}

enum ShazamPlaylist {
    static let tracks: [JukeboxTrack] = {
        guard let asset = NSDataAsset(name: "final_shazam_list") else { return [] }
        let raw = String(decoding: asset.data, as: UTF8.self)
        guard !raw.isEmpty else { return [] }

        let lines = raw.split(whereSeparator: \.isNewline)
        var seen: Set<String> = []
        var items: [JukeboxTrack] = []
        let legalChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")

        for rawLine in lines {
            let line = String(rawLine).trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let fields = Self.csvFields(line: line)
            guard fields.count >= 2 else { continue }

            let rawID = fields[0].trimmingCharacters(in: .whitespaces)
            let filtered = String(rawID.unicodeScalars.filter { legalChars.contains($0) })
            let videoID = String(filtered.prefix(11))
            guard videoID.count == 11 else { continue }

            guard seen.insert(videoID).inserted else { continue }

            var title = fields[1]
            if title.first == "\"" && title.last == "\"" {
                title.removeFirst()
                if !title.isEmpty { title.removeLast() }
            }
            title = title.replacingOccurrences(of: "\"\"", with: "\"")

            items.append(JukeboxTrack(id: videoID, title: title))
        }

        return items
    }()

    private static func csvFields(line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 2
                        continue
                    }
                    inQuotes = false
                    i += 1
                    continue
                }
                current.append(c)
                i += 1
                continue
            }
            if c == "," {
                fields.append(current)
                current = ""
                i += 1
                continue
            }
            if c == "\"" {
                inQuotes = true
                i += 1
                continue
            }
            current.append(c)
            i += 1
        }
        fields.append(current)
        return fields
    }
}
