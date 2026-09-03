import Foundation

struct DraftFiring: Identifiable, Equatable {
    var id: Int { laneNumber }
    let laneNumber: Int
    let cadetID: UUID?
    let practiceID: UUID?
}

struct DraftDetail: Equatable {
    let firings: [DraftFiring]
}
