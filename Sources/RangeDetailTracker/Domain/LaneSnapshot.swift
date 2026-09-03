struct LaneSnapshot: Identifiable, Equatable {
    var id: Int { number }
    let number: Int
    let active: Bool
}
