import Foundation
import Observation

@Observable
final class Practice: Codable, Identifiable {
    var id: UUID
    var name: String
    var order: Int
    var scoringType: ScoringType
    var passMark: Int?
    var esPassMark: Int?
    var pvPassMark: Int?

    init(
        id: UUID = UUID(),
        name: String,
        order: Int,
        scoringType: ScoringType,
        passMark: Int? = nil,
        esPassMark: Int? = nil,
        pvPassMark: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.scoringType = scoringType
        self.passMark = passMark
        self.esPassMark = esPassMark
        self.pvPassMark = pvPassMark
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, order, scoringType, passMark, esPassMark, pvPassMark
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(Int.self, forKey: .order)
        scoringType = try container.decode(ScoringType.self, forKey: .scoringType)
        passMark = try container.decodeIfPresent(Int.self, forKey: .passMark)
        esPassMark = try container.decodeIfPresent(Int.self, forKey: .esPassMark)
        pvPassMark = try container.decodeIfPresent(Int.self, forKey: .pvPassMark)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(order, forKey: .order)
        try container.encode(scoringType, forKey: .scoringType)
        try container.encodeIfPresent(passMark, forKey: .passMark)
        try container.encodeIfPresent(esPassMark, forKey: .esPassMark)
        try container.encodeIfPresent(pvPassMark, forKey: .pvPassMark)
    }
}
