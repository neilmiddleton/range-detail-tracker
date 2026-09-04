import Foundation

enum ButtRegisterBuilder {
    static func rows(for session: Session) -> [ButtRegisterRow] {
        let practices = session.practices.sorted { $0.order < $1.order }
        return session.cadets
            .sorted { $0.name < $1.name }
            .map { cadet in
                ButtRegisterRow(
                    id: cadet.id,
                    cadetName: cadet.name,
                    bestResults: practices.map { practice in
                        bestResult(forCadet: cadet.id, practice: practice, session: session)
                    }
                )
            }
    }

    private static func bestResult(forCadet cadetID: UUID, practice: Practice, session: Session) -> BestPracticeResult {
        let firings = session.details
            .flatMap(\.firings)
            .filter { $0.cadetID == cadetID && $0.practiceID == practice.id }
            .filter { !ScoringRule.isVoidAttempt(scoringType: practice.scoringType, score: $0.score, esScore: $0.esScore, pvScore: $0.pvScore) }

        switch practice.scoringType {
        case .standard:
            let best = firings.compactMap(\.score).min()
            let outcome = firings.first { $0.score == best }?.outcome
            return BestPracticeResult(practiceID: practice.id, scoringType: .standard, score: best, esScore: nil, pvScore: nil, outcome: outcome)
        case .zeroing:
            let zeroed = firings.filter { $0.esScore != nil && $0.pvScore != nil }
            let best = zeroed.min { lhs, rhs -> Bool in
                let lhsTotal: Int = lhs.esScore! + lhs.pvScore!
                let rhsTotal: Int = rhs.esScore! + rhs.pvScore!
                return lhsTotal < rhsTotal
            }
            return BestPracticeResult(practiceID: practice.id, scoringType: .zeroing, score: nil, esScore: best?.esScore, pvScore: best?.pvScore, outcome: best?.outcome)
        }
    }
}
