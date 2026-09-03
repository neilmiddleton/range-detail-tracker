import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ButtRegisterView: View {
    let store: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var exportError: String?

    private var rows: [ButtRegisterRow] {
        ButtRegisterBuilder.rows(for: store.session)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Butt Register").font(.title2)
                Spacer()
                Button("Export CSV") { exportCSV() }
                Button("Done") { dismiss() }
            }
            Table(rows) {
                TableColumn("Detail") { Text("\($0.detailSequenceNumber)") }
                TableColumn("Lane") { Text("\($0.laneNumber)") }
                TableColumn("Cadet") { Text($0.cadetName) }
                TableColumn("Practice") { Text($0.practiceName) }
                TableColumn("Score") { Text($0.score.map(String.init) ?? "") }
                TableColumn("ES") { Text($0.esScore.map(String.init) ?? "") }
                TableColumn("PV") { Text($0.pvScore.map(String.init) ?? "") }
                TableColumn("Outcome") { Text($0.outcome?.rawValue ?? "") }
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 400)
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        ), presenting: exportError) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "butt-register.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let csv = ButtRegisterCSVExporter.csv(for: rows)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            exportError = error.localizedDescription
        }
    }
}
