import Foundation

enum ProgressionRule {
    static func hasPassed(practiceID: UUID, cadetID: UUID, firings: [FiringRecord]) -> Bool {
        firings.contains { $0.cadetID == cadetID && $0.practiceID == practiceID && $0.outcome == .pass }
    }

    static func currentPractice(for cadetID: UUID, practices: [PracticeSnapshot], firings: [FiringRecord]) -> PracticeSnapshot? {
        let ordered = practices.sorted { $0.order < $1.order }
        guard let final = ordered.last else { return nil }
        for practice in ordered where !hasPassed(practiceID: practice.id, cadetID: cadetID, firings: firings) {
            return practice
        }
        return final
    }
}
