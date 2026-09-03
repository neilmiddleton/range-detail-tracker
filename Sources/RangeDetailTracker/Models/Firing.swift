import Foundation
import Observation

@Observable
final class Firing: Codable, Identifiable {
    var id: UUID
    var laneNumber: Int
    var cadetID: UUID
    var practiceID: UUID
    var score: Int?
    var esScore: Int?
    var pvScore: Int?
    var outcome: Outcome?

    init(id: UUID = UUID(), laneNumber: Int, cadetID: UUID, practiceID: UUID) {
        self.id = id
        self.laneNumber = laneNumber
        self.cadetID = cadetID
        self.practiceID = practiceID
    }

    private enum CodingKeys: String, CodingKey {
        case id, laneNumber, cadetID, practiceID, score, esScore, pvScore, outcome
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        laneNumber = try container.decode(Int.self, forKey: .laneNumber)
        cadetID = try container.decode(UUID.self, forKey: .cadetID)
        practiceID = try container.decode(UUID.self, forKey: .practiceID)
        score = try container.decodeIfPresent(Int.self, forKey: .score)
        esScore = try container.decodeIfPresent(Int.self, forKey: .esScore)
        pvScore = try container.decodeIfPresent(Int.self, forKey: .pvScore)
        outcome = try container.decodeIfPresent(Outcome.self, forKey: .outcome)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(laneNumber, forKey: .laneNumber)
        try container.encode(cadetID, forKey: .cadetID)
        try container.encode(practiceID, forKey: .practiceID)
        try container.encodeIfPresent(score, forKey: .score)
        try container.encodeIfPresent(esScore, forKey: .esScore)
        try container.encodeIfPresent(pvScore, forKey: .pvScore)
        try container.encodeIfPresent(outcome, forKey: .outcome)
    }
}
