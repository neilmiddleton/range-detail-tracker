enum ButtRegisterCSVExporter {
    static func csv(for rows: [ButtRegisterRow], practices: [Practice]) -> String {
        let orderedPractices = practices.sorted { $0.order < $1.order }
        var lines = [(["Cadet"] + orderedPractices.map(\.name)).map(csvField).joined(separator: ",")]
        for row in rows {
            let fields = [row.cadetName] + orderedPractices.map { row.bestResult(for: $0.id)?.displayValue ?? "" }
            lines.append(fields.map(csvField).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func csvField(_ value: String) -> String {
        let quote = "\""
        if value.contains(",") || value.contains(quote) || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: quote, with: quote + quote)
            return quote + escaped + quote
        }
        return value
    }
}
