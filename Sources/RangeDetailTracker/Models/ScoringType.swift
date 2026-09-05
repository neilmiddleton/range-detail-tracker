enum ScoringType: String, Codable, CaseIterable {
    /// Lower is better (e.g. group size in mm). Pass if score <= passMark.
    case standard
    /// Two-stage lower-is-better scoring (e.g. zeroing ES/PV, both in mm).
    case zeroing
    /// Higher is better (points out of an HPS). Pass if score >= passMark.
    case points
    /// No fixed standard — any non-zero score counts as a pass (a zero still
    /// means the practice wasn't actually fired, e.g. a stoppage).
    case completion
}
