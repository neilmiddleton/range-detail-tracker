import Foundation

struct CadetSnapshot: Identifiable, Equatable {
    let id: UUID
    let name: String
    let nextOverridePracticeID: UUID?
}
