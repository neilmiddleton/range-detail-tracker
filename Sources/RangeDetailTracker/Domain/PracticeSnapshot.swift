import Foundation

struct PracticeSnapshot: Identifiable, Equatable {
    let id: UUID
    let name: String
    let order: Int
    let scoringType: ScoringType
    let passMark: Int?
    let esPassMark: Int?
    let pvPassMark: Int?
}
