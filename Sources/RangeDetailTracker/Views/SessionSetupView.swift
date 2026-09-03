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
                Text("A previous session was found.").font(.title2)
                Text("Resume it, or start a new session (the previous session's data stays saved on disk).")
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Resume Previous Session") {
                        store = SessionStore(session: resumableSession)
                    }
                    Button("Start New Session") {
                        startingFresh = true
                    }
                }
            }
            .padding()
            .frame(minWidth: 480, minHeight: 240)
        } else {
            Form {
                Section("Lanes") {
                    Stepper("Lane count: \(laneCount)", value: $laneCount, in: 1...10)
                }
                Section("Practices") {
                    ForEach($practiceDrafts) { $draft in
                        practiceRow($draft)
                    }
                    Button("Add practice") {
                        practiceDrafts.append(PracticeDraft())
                    }
                }
                Section("Cadets (one name per line)") {
                    TextEditor(text: $cadetNamesText)
                        .frame(minHeight: 120)
                }
                Button("Start Session") {
                    store = SessionStore(session: makeSession())
                }
                .disabled(!isValid)
            }
            .padding()
            .frame(minWidth: 480, minHeight: 480)
            .onAppear {
                if resumableSession == nil {
                    resumableSession = SessionPersistence.load()
                }
            }
        }
    }

    @ViewBuilder
    private func practiceRow(_ draft: Binding<PracticeDraft>) -> some View {
        HStack {
            TextField("Name (e.g. GP1)", text: draft.name)
                .frame(minWidth: 120, maxWidth: 260)
            Picker("Scoring", selection: draft.scoringType) {
                Text("Standard").tag(ScoringType.standard)
                Text("Zeroing").tag(ScoringType.zeroing)
            }
            .labelsHidden()
            if draft.wrappedValue.scoringType == .standard {
                TextField("Pass mark", value: draft.passMark, format: .number)
                    .frame(width: 80)
            } else {
                TextField("ES pass mark", value: draft.esPassMark, format: .number)
                    .frame(width: 90)
                TextField("PV pass mark", value: draft.pvPassMark, format: .number)
                    .frame(width: 90)
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
