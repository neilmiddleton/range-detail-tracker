import Foundation
import Observation

@Observable
final class Detail: Codable, Identifiable {
    var id: UUID
    var sequenceNumber: Int
    var firedAt: Date
    var firings: [Firing]

    init(id: UUID = UUID(), sequenceNumber: Int, firedAt: Date = .now) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.firedAt = firedAt
        self.firings = []
    }

    private enum CodingKeys: String, CodingKey {
        case id, sequenceNumber, firedAt, firings
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        firedAt = try container.decode(Date.self, forKey: .firedAt)
        firings = try container.decode([Firing].self, forKey: .firings)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sequenceNumber, forKey: .sequenceNumber)
        try container.encode(firedAt, forKey: .firedAt)
        try container.encode(firings, forKey: .firings)
    }
}
