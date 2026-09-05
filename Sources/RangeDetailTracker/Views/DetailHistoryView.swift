import SwiftUI

struct DetailHistoryView: View {
    let store: SessionStore

    private let detailColumnWidth: CGFloat = 90

    var body: some View {
        let details = store.session.details.sorted { $0.sequenceNumber < $1.sequenceNumber }
        let cadets = store.session.cadets.sorted { $0.name < $1.name }
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "History")
            if details.isEmpty {
                Text("No details fired yet.").foregroundStyle(.secondary)
            } else {
                // Cadets down the left, one column per detail along the top —
                // each cell is a pass/fail box naming the practice fired, so
                // the whole day's progress is readable at a glance.
                Table(cadets) {
                    TableColumn("Cadet") { cadet in Text(cadet.name) }
                        .width(min: cadetColumnWidth(for: cadets))
                    TableColumnForEach(details) { detail in
                        TableColumn("Detail \(detail.sequenceNumber)") { cadet in
                            outcomeBox(cadet: cadet, detail: detail)
                        }
                        .width(detailColumnWidth)
                    }
                }
                .frame(minHeight: CGFloat(cadets.count) * 32 + 40)
            }
        }
    }

    /// A rough per-character estimate so the column never clips a cadet's name,
    /// even though Table doesn't measure text itself before laying out columns.
    private func cadetColumnWidth(for cadets: [Cadet]) -> CGFloat {
        let longestName = cadets.map(\.name.count).max() ?? 6
        return CGFloat(longestName) * 8 + 24
    }

    @ViewBuilder
    private func outcomeBox(cadet: Cadet, detail: Detail) -> some View {
        if let firing = detail.firings.first(where: { $0.cadetID == cadet.id }) {
            let practiceName = store.session.practices.first { $0.id == firing.practiceID }?.name ?? "?"
            Text(abbreviate(practiceName))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(boxColor(for: firing.outcome), in: RoundedRectangle(cornerRadius: 4))
        } else {
            Text("")
        }
    }

    /// Catalog practice names lead with their code (e.g. "AR4.2", "GP3 Grouping (Sitting, DCCT)"
    /// -> "GP3") — the box only has room for that, not the full descriptive name.
    private func abbreviate(_ practiceName: String) -> String {
        practiceName.split(separator: " ").first.map(String.init) ?? practiceName
    }

    private func boxColor(for outcome: Outcome?) -> Color {
        switch outcome {
        case .pass: Theme.pass
        case .fail: Theme.fail
        case nil: Color.gray
        }
    }
}
