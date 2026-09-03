import Foundation
import Observation

@Observable
final class Cadet: Codable, Identifiable {
    var id: UUID
    var name: String
    var nextOverridePracticeID: UUID?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, nextOverridePracticeID
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nextOverridePracticeID = try container.decodeIfPresent(UUID.self, forKey: .nextOverridePracticeID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(nextOverridePracticeID, forKey: .nextOverridePracticeID)
    }
}
