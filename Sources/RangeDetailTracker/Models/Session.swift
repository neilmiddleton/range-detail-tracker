import Foundation
import Observation

@Observable
final class Session: Codable, Identifiable {
    var id: UUID
    var date: Date
    var laneCount: Int
    var practices: [Practice]
    var cadets: [Cadet]
    var lanes: [Lane]
    var details: [Detail]

    init(id: UUID = UUID(), date: Date = .now, laneCount: Int) {
        self.id = id
        self.date = date
        self.laneCount = laneCount
        self.practices = []
        self.cadets = []
        self.lanes = []
        self.details = []
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, laneCount, practices, cadets, lanes, details
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        laneCount = try container.decode(Int.self, forKey: .laneCount)
        practices = try container.decode([Practice].self, forKey: .practices)
        cadets = try container.decode([Cadet].self, forKey: .cadets)
        lanes = try container.decode([Lane].self, forKey: .lanes)
        details = try container.decode([Detail].self, forKey: .details)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(laneCount, forKey: .laneCount)
        try container.encode(practices, forKey: .practices)
        try container.encode(cadets, forKey: .cadets)
        try container.encode(lanes, forKey: .lanes)
        try container.encode(details, forKey: .details)
    }
}
