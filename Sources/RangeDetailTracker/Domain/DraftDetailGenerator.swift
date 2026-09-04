import Foundation

enum DraftDetailGenerator {
    static func nextDetail(
        cadets: [CadetSnapshot],
        practices: [PracticeSnapshot],
        lanes: [LaneSnapshot],
        firings: [FiringRecord]
    ) -> DraftDetail {
        let activeLanes = lanes.filter(\.active).sorted { $0.number < $1.number }
        guard !activeLanes.isEmpty, !practices.isEmpty else {
            return DraftDetail(firings: activeLanes.map { DraftFiring(laneNumber: $0.number, cadetID: nil, practiceID: nil) })
        }

        var practiceForCadet: [UUID: PracticeSnapshot] = [:]
        for cadet in cadets {
            if let overrideID = cadet.nextOverridePracticeID,
               let overridePractice = practices.first(where: { $0.id == overrideID }) {
                practiceForCadet[cadet.id] = overridePractice
            } else if let resolved = ProgressionRule.currentPractice(for: cadet.id, practices: practices, firings: firings) {
                practiceForCadet[cadet.id] = resolved
            }
        }

        // A zero-scored firing means the practice was never actually fired (e.g. a
        // stoppage), so it shouldn't count against a cadet's place in the fairness
        // rotation, or make them "sticky" to a lane they never really zeroed on.
        let validFirings = effectiveFirings(practices: practices, firings: firings)

        var cadetIDsByPractice: [UUID: [UUID]] = [:]
        for cadet in cadets {
            guard let practice = practiceForCadet[cadet.id] else { continue }
            cadetIDsByPractice[practice.id, default: []].append(cadet.id)
        }
        for practiceID in cadetIDsByPractice.keys {
            cadetIDsByPractice[practiceID] = FairnessRanking.rank(cadetIDs: cadetIDsByPractice[practiceID] ?? [], firings: validFirings)
        }

        let orderedPractices = practices
            .sorted { $0.order < $1.order }
            .filter { !(cadetIDsByPractice[$0.id] ?? []).isEmpty }

        let stickyLaneByCadet = stickyLanes(practices: practices, firings: validFirings)

        var draftFirings: [DraftFiring] = []
        var laneIndex = 0
        for practice in orderedPractices {
            let queue = cadetIDsByPractice[practice.id] ?? []
            guard laneIndex < activeLanes.count, !queue.isEmpty else { continue }

            let laneCountForPractice = min(queue.count, activeLanes.count - laneIndex)
            let laneBlock = Array(activeLanes[laneIndex..<(laneIndex + laneCountForPractice)])

            // A cadet who has previously fired a zeroing practice is tied to a
            // specific rifle kept on that lane, so keep them on it whenever
            // their sticky lane falls within this practice's block of lanes.
            var laneNumberByCadet: [UUID: Int] = [:]
            var claimedLanes: Set<Int> = []
            var unplacedCadetIDs: [UUID] = []
            for cadetID in queue {
                if let stickyLane = stickyLaneByCadet[cadetID],
                   laneBlock.contains(where: { $0.number == stickyLane }),
                   !claimedLanes.contains(stickyLane) {
                    laneNumberByCadet[cadetID] = stickyLane
                    claimedLanes.insert(stickyLane)
                } else {
                    unplacedCadetIDs.append(cadetID)
                }
            }
            var freeLanes = laneBlock.filter { !claimedLanes.contains($0.number) }
            for cadetID in unplacedCadetIDs {
                guard !freeLanes.isEmpty else { break }
                laneNumberByCadet[cadetID] = freeLanes.removeFirst().number
            }

            for lane in laneBlock {
                guard let cadetID = laneNumberByCadet.first(where: { $0.value == lane.number })?.key else { continue }
                draftFirings.append(DraftFiring(laneNumber: lane.number, cadetID: cadetID, practiceID: practice.id))
            }

            laneIndex += laneCountForPractice
            if laneIndex >= activeLanes.count { break }
        }
        while laneIndex < activeLanes.count {
            draftFirings.append(DraftFiring(laneNumber: activeLanes[laneIndex].number, cadetID: nil, practiceID: nil))
            laneIndex += 1
        }

        return DraftDetail(firings: draftFirings.sorted { $0.laneNumber < $1.laneNumber })
    }

    private static func effectiveFirings(practices: [PracticeSnapshot], firings: [FiringRecord]) -> [FiringRecord] {
        let scoringTypeByPracticeID = Dictionary(uniqueKeysWithValues: practices.map { ($0.id, $0.scoringType) })
        return firings.filter { firing in
            guard let scoringType = scoringTypeByPracticeID[firing.practiceID] else { return true }
            return !ScoringRule.isVoidAttempt(scoringType: scoringType, score: firing.score, esScore: firing.esScore, pvScore: firing.pvScore)
        }
    }

    /// The lane each cadet last zeroed on, if any — most recent zeroing firing wins.
    private static func stickyLanes(practices: [PracticeSnapshot], firings: [FiringRecord]) -> [UUID: Int] {
        let zeroingPracticeIDs = Set(practices.filter { $0.scoringType == .zeroing }.map(\.id))
        var stickyLaneByCadet: [UUID: Int] = [:]
        for firing in firings.sorted(by: { $0.sequenceNumber > $1.sequenceNumber }) {
            guard stickyLaneByCadet[firing.cadetID] == nil, zeroingPracticeIDs.contains(firing.practiceID) else { continue }
            stickyLaneByCadet[firing.cadetID] = firing.laneNumber
        }
        return stickyLaneByCadet
    }
}
