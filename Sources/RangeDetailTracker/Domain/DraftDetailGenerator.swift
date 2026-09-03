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

        var cadetIDsByPractice: [UUID: [UUID]] = [:]
        for cadet in cadets {
            guard let practice = practiceForCadet[cadet.id] else { continue }
            cadetIDsByPractice[practice.id, default: []].append(cadet.id)
        }
        for practiceID in cadetIDsByPractice.keys {
            cadetIDsByPractice[practiceID] = FairnessRanking.rank(cadetIDs: cadetIDsByPractice[practiceID] ?? [], firings: firings)
        }

        let orderedPractices = practices
            .sorted { $0.order < $1.order }
            .filter { !(cadetIDsByPractice[$0.id] ?? []).isEmpty }

        var draftFirings: [DraftFiring] = []
        var laneIndex = 0
        for practice in orderedPractices {
            var queue = cadetIDsByPractice[practice.id] ?? []
            while laneIndex < activeLanes.count, !queue.isEmpty {
                let cadetID = queue.removeFirst()
                draftFirings.append(DraftFiring(laneNumber: activeLanes[laneIndex].number, cadetID: cadetID, practiceID: practice.id))
                laneIndex += 1
            }
            if laneIndex >= activeLanes.count { break }
        }
        while laneIndex < activeLanes.count {
            draftFirings.append(DraftFiring(laneNumber: activeLanes[laneIndex].number, cadetID: nil, practiceID: nil))
            laneIndex += 1
        }

        return DraftDetail(firings: draftFirings.sorted { $0.laneNumber < $1.laneNumber })
    }
}
