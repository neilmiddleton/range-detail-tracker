import SwiftUI

struct PracticeDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var scoringType: ScoringType = .standard
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

    private let nameColumnWidth: CGFloat = 90
    private let scoringColumnWidth: CGFloat = 130
    private let markColumnWidth: CGFloat = 130
    private let practiceNameMaxLength = 10

    private var practiceColumnHeader: some View {
        HStack(spacing: 12) {
            Text("Name").frame(width: nameColumnWidth, alignment: .leading)
            Text("Scoring").frame(width: scoringColumnWidth, alignment: .leading)
            Text("Pass Mark").frame(width: markColumnWidth, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func practiceRow(_ draft: Binding<PracticeDraft>) -> some View {
        HStack(spacing: 12) {
            TextField("e.g. GP1", text: draft.name)
                .labelsHidden()
                .frame(width: nameColumnWidth)
                .onChange(of: draft.wrappedValue.name) { _, newValue in
                    if newValue.count > practiceNameMaxLength {
                        draft.wrappedValue.name = String(newValue.prefix(practiceNameMaxLength))
                    }
                }
            Picker("Scoring", selection: draft.scoringType) {
                Text("Standard").tag(ScoringType.standard)
                Text("Zeroing").tag(ScoringType.zeroing)
            }
            .labelsHidden()
            .frame(width: scoringColumnWidth)
            if draft.wrappedValue.scoringType == .standard {
                TextField("Pass mark", value: draft.passMark, format: .number)
                    .labelsHidden()
                    .frame(width: markColumnWidth)
            } else {
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
            }
        }
    }

    private var isValid: Bool {
        !practiceDrafts.isEmpty && practiceDrafts.allSatisfy { !$0.name.isEmpty } && !cadetNames.isEmpty
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
            let practice = Practice(
                name: draft.name,
                order: index,
                scoringType: draft.scoringType,
                passMark: draft.scoringType == .standard ? draft.passMark : nil,
                esPassMark: draft.scoringType == .zeroing ? draft.esPassMark : nil,
                pvPassMark: draft.scoringType == .zeroing ? draft.pvPassMark : nil
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
