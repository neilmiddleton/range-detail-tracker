import Foundation

enum SessionPersistence {
    static func fileURL() -> URL {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RangeDetailTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("current-session.json")
    }

    static func save(_ session: Session) {
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: fileURL(), options: .atomic)
        } catch {
            print("Warning: failed to save session: \(error)")
        }
    }

    static func load() -> Session? {
        guard let data = try? Data(contentsOf: fileURL()) else { return nil }
        return try? JSONDecoder().decode(Session.self, from: data)
    }
}
