import Foundation

/// One cadet's best (lowest, since lower scores pass) result on each practice —
/// the summary a butt register reports, not a log of every individual firing.
struct ButtRegisterRow: Identifiable {
    let id: UUID
    let cadetName: String
    let bestResults: [BestPracticeResult]

    func bestResult(for practiceID: UUID) -> BestPracticeResult? {
        bestResults.first { $0.practiceID == practiceID }
    }
}

struct BestPracticeResult: Identifiable {
    var id: UUID { practiceID }
    let practiceID: UUID
    let scoringType: ScoringType
    let score: Int?
    let esScore: Int?
    let pvScore: Int?
    let outcome: Outcome?

    var hasResult: Bool {
        switch scoringType {
        case .standard, .points, .completion: return score != nil
        case .zeroing: return esScore != nil && pvScore != nil
        }
    }

    /// A single display value: the score for standard/points/completion practices, "ES/PV" for zeroing.
    var displayValue: String {
        switch scoringType {
        case .standard, .points, .completion:
            return score.map(String.init) ?? ""
        case .zeroing:
            guard let esScore, let pvScore else { return "" }
            return "\(esScore)/\(pvScore)"
        }
    }
}
