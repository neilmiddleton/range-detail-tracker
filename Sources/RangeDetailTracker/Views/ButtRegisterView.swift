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

    private var practices: [Practice] {
        store.session.practices.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SectionHeader(title: "Butt Register")
                Spacer()
                Button("Export CSV") { exportCSV() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentFill)
                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
            }
            // One row per cadet, one column per practice, showing their best
            // (lowest) score on that practice — the register a coach hands
            // out at the end of the day, not a log of every individual shot.
            Table(rows) {
                TableColumn("Cadet") { Text($0.cadetName) }
                TableColumnForEach(practices) { practice in
                    TableColumn(practice.name) { row in
                        bestResultCell(row.bestResult(for: practice.id))
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 400)
        .dynamicTypeSize(.large)
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        ), presenting: exportError) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    @ViewBuilder
    private func bestResultCell(_ result: BestPracticeResult?) -> some View {
        if let result, result.hasResult {
            HStack(spacing: 4) {
                Text(result.displayValue)
                if let outcome = result.outcome {
                    Image(systemName: outcome == .pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(outcome == .pass ? Theme.pass : Theme.fail)
                }
            }
        } else {
            Text("—").foregroundStyle(.secondary)
        }
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "butt-register.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let csv = ButtRegisterCSVExporter.csv(for: rows, practices: practices)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            exportError = error.localizedDescription
        }
    }
}
