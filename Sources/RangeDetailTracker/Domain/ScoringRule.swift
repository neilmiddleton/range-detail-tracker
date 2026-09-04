enum ScoringRule {
    static func outcome(for practice: PracticeSnapshot, score: Int?, esScore: Int?, pvScore: Int?) -> Outcome? {
        switch practice.scoringType {
        case .standard:
            guard let score, let passMark = practice.passMark else { return nil }
            if score == 0 { return .fail } // 0 means not actually fired, never a pass
            return score <= passMark ? .pass : .fail
        case .zeroing:
            guard let esScore, let pvScore,
                  let esPassMark = practice.esPassMark,
                  let pvPassMark = practice.pvPassMark
            else { return nil }
            if esScore == 0 || pvScore == 0 { return .fail } // 0 means not actually fired, never a pass
            return (esScore <= esPassMark && pvScore <= pvPassMark) ? .pass : .fail
        }
    }

    /// A zero score means the practice was never actually fired (e.g. a
    /// stoppage) — the attempt is void and shouldn't count against the
    /// cadet's place in the fairness rotation, as if they hadn't fired it.
    static func isVoidAttempt(scoringType: ScoringType, score: Int?, esScore: Int?, pvScore: Int?) -> Bool {
        switch scoringType {
        case .standard:
            return score == 0
        case .zeroing:
            return esScore == 0 || pvScore == 0
        }
    }
}
