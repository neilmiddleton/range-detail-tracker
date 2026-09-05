import SwiftUI

struct PracticeDraft: Identifiable {
    let id = UUID()
    var catalogEntry: PracticeCatalog.Entry?
    var passMark: Int = 0
    var esPassMark: Int = 0
    var pvPassMark: Int = 0
}

struct SessionSetupView: View {
    @State private var laneCount: Int = 5
    @State private var practiceDrafts: [PracticeDraft] = [PracticeDraft()]
    @State private var cadetNamesText: String = ""
    @State private var store: SessionStore?
    @State private var resumableSession: Session?
    @State private var startingFresh = false

    var body: some View {
        if let store {
            RangeView(store: store)
        } else if let resumableSession, !startingFresh {
            VStack(spacing: 16) {
                SectionHeader(title: "A previous session was found")
                Text("Resume it, or start a new session (the previous session's data stays saved on disk).")
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Resume Previous Session") {
                        store = SessionStore(session: resumableSession)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentFill)
                    Button("Start New Session") {
                        startingFresh = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(minWidth: 480, minHeight: 240)
            .tint(Theme.accentFill)
            .dynamicTypeSize(.large)
        } else {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Text("Lane count: \(laneCount)")
                        Stepper("", value: $laneCount, in: 1...10)
                            .labelsHidden()
                    }
                } header: {
                    SectionHeader(title: "Lanes")
                }
                Section {
                    practiceColumnHeader
                    ForEach($practiceDrafts) { $draft in
                        practiceRow($draft)
                    }
                    Button("Add practice") {
                        practiceDrafts.append(PracticeDraft())
                    }
                    .buttonStyle(.bordered)
                } header: {
                    SectionHeader(title: "Practices")
                }
                Section {
                    TextEditor(text: $cadetNamesText)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                } header: {
                    SectionHeader(title: "Cadets (one name per line)")
                }
                Button("Start Session") {
                    store = SessionStore(session: makeSession())
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentFill)
                .disabled(!isValid)
            }
            .padding()
            .frame(minWidth: 560, minHeight: 520)
            .tint(Theme.accentFill)
            .dynamicTypeSize(.large)
            .onAppear {
                if resumableSession == nil {
                    resumableSession = SessionPersistence.load()
                }
            }
        }
    }

    private let nameColumnWidth: CGFloat = 320
    private let scoringColumnWidth: CGFloat = 90
    private let markColumnWidth: CGFloat = 100

    private var practiceColumnHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "minus.circle.fill").opacity(0)
            Text("Practice").frame(width: nameColumnWidth, alignment: .leading)
            Text("Scoring").frame(width: scoringColumnWidth, alignment: .leading)
            Text("Pass Mark").frame(width: markColumnWidth, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private static let arCatalogEntries = PracticeCatalog.entries.filter { $0.name.hasPrefix("AR") }
    private static let sbCatalogEntries = PracticeCatalog.entries.filter { $0.name.hasPrefix("SB") }
    private static let gpCatalogEntries = PracticeCatalog.entries.filter { $0.name.hasPrefix("GP") }

    @ViewBuilder
    private func practiceRow(_ draft: Binding<PracticeDraft>) -> some View {
        HStack(spacing: 12) {
            Button {
                practiceDrafts.removeAll { $0.id == draft.wrappedValue.id }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(Theme.fail)
            }
            .buttonStyle(.plain)
            .disabled(practiceDrafts.count <= 1)

            Picker("Practice", selection: draft.catalogEntry) {
                Text("— Select a practice —").tag(PracticeCatalog.Entry?.none)
                Section("Air Rifle (AR)") {
                    ForEach(Self.arCatalogEntries) { entry in
                        Text(entry.name).tag(Optional(entry))
                    }
                }
                Section("Small Bore (SB)") {
                    ForEach(Self.sbCatalogEntries) { entry in
                        Text(entry.name).tag(Optional(entry))
                    }
                }
                Section("GP Rifle — indoor/DCCT") {
                    ForEach(Self.gpCatalogEntries) { entry in
                        Text(entry.name).tag(Optional(entry))
                    }
                }
            }
            .labelsHidden()
            .frame(width: nameColumnWidth)
            .onChange(of: draft.wrappedValue.catalogEntry) { _, newEntry in
                // Pre-fill the ACP-specified default for the chosen practice — still editable,
                // since a local SOP may set a different standard.
                draft.wrappedValue.passMark = newEntry?.defaultPassMark ?? 0
                draft.wrappedValue.esPassMark = newEntry?.defaultEsPassMark ?? 0
                draft.wrappedValue.pvPassMark = newEntry?.defaultPvPassMark ?? 0
            }

            Text(scoringLabel(for: draft.wrappedValue.catalogEntry?.scoringType))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: scoringColumnWidth, alignment: .leading)

            switch draft.wrappedValue.catalogEntry?.scoringType {
            case .standard, .points:
                TextField("Pass mark", value: draft.passMark, format: .number)
                    .labelsHidden()
                    .frame(width: markColumnWidth)
            case .zeroing:
                HStack(spacing: 6) {
                    Text("ES").foregroundStyle(.secondary)
                    TextField("ES", value: draft.esPassMark, format: .number)
                        .labelsHidden()
                        .frame(width: markColumnWidth)
                    Text("PV").foregroundStyle(.secondary)
                    TextField("PV", value: draft.pvPassMark, format: .number)
                        .labelsHidden()
                        .frame(width: markColumnWidth)
                }
            case .completion, nil:
                Text("—").foregroundStyle(.secondary).frame(width: markColumnWidth, alignment: .leading)
            }
        }
    }

    private func scoringLabel(for scoringType: ScoringType?) -> String {
        switch scoringType {
        case .standard: "Standard"
        case .zeroing: "Zeroing"
        case .points: "Points"
        case .completion: "Completion"
        case nil: ""
        }
    }

    private var isValid: Bool {
        !practiceDrafts.isEmpty && practiceDrafts.allSatisfy { $0.catalogEntry != nil } && !cadetNames.isEmpty
    }

    private var cadetNames: [String] {
        cadetNamesText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func makeSession() -> Session {
        let session = Session(laneCount: laneCount)
        for number in 1...laneCount {
            session.lanes.append(Lane(number: number))
        }
        for (index, draft) in practiceDrafts.enumerated() {
            guard let catalogEntry = draft.catalogEntry else { continue }
            let scoringType = catalogEntry.scoringType
            let practice = Practice(
                name: catalogEntry.name,
                order: index,
                scoringType: scoringType,
                passMark: (scoringType == .standard || scoringType == .points) ? draft.passMark : nil,
                esPassMark: scoringType == .zeroing ? draft.esPassMark : nil,
                pvPassMark: scoringType == .zeroing ? draft.pvPassMark : nil
            )
            session.practices.append(practice)
        }
        for name in cadetNames {
            session.cadets.append(Cadet(name: name))
        }
        SessionPersistence.save(session)
        return session
    }
}
