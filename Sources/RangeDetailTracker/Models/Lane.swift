import Observation

@Observable
final class Lane: Codable, Identifiable {
    var id: Int { number }
    var number: Int
    var active: Bool

    init(number: Int, active: Bool = true) {
        self.number = number
        self.active = active
    }

    private enum CodingKeys: String, CodingKey {
        case number, active
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        active = try container.decode(Bool.self, forKey: .active)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(active, forKey: .active)
    }
}
