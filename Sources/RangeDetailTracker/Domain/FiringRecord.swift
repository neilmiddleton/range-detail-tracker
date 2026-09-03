import Foundation

struct FiringRecord: Identifiable, Equatable {
    let id: UUID
    let detailID: UUID
    let sequenceNumber: Int
    let firedAt: Date
    let laneNumber: Int
    let cadetID: UUID
    let practiceID: UUID
    let score: Int?
    let esScore: Int?
    let pvScore: Int?
    let outcome: Outcome?
}
