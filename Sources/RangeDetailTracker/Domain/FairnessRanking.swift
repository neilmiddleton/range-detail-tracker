import Foundation

enum FairnessRanking {
    /// Ranks cadet IDs: longest since last fired detail first (never fired ranks
    /// first of all), then fewest details fired this session, then a stable
    /// deterministic tiebreak.
    static func rank(cadetIDs: [UUID], firings: [FiringRecord]) -> [UUID] {
        func lastFiredSequence(_ cadetID: UUID) -> Int {
            firings.filter { $0.cadetID == cadetID }.map(\.sequenceNumber).max() ?? -1
        }
        func firedCount(_ cadetID: UUID) -> Int {
            firings.filter { $0.cadetID == cadetID }.count
        }
        return cadetIDs.sorted { a, b in
            let lastA = lastFiredSequence(a)
            let lastB = lastFiredSequence(b)
            if lastA != lastB { return lastA < lastB }
            let countA = firedCount(a)
            let countB = firedCount(b)
            if countA != countB { return countA < countB }
            return a.uuidString < b.uuidString
        }
    }
}
