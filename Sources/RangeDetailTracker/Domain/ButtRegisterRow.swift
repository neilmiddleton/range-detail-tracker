struct ButtRegisterRow: Identifiable {
    var id: String { "\(detailSequenceNumber)-\(laneNumber)" }
    let detailSequenceNumber: Int
    let laneNumber: Int
    let cadetName: String
    let practiceName: String
    let score: Int?
    let esScore: Int?
    let pvScore: Int?
    let outcome: Outcome?
}
