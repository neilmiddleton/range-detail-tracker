enum ButtRegisterCSVExporter {
    static func csv(for rows: [ButtRegisterRow]) -> String {
        var lines = ["Detail,Lane,Cadet,Practice,Score,ES,PV,Outcome"]
        for row in rows {
            let fields = [
                String(row.detailSequenceNumber),
                String(row.laneNumber),
                csvField(row.cadetName),
                csvField(row.practiceName),
                row.score.map(String.init) ?? "",
                row.esScore.map(String.init) ?? "",
                row.pvScore.map(String.init) ?? "",
                row.outcome?.rawValue ?? "",
            ]
            lines.append(fields.joined(separator: ","))
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
