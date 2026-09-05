/// The fixed set of practices a session's practice list may be built from —
/// sourced from ACP 18 Vol 3 (2022), restricted to the indoor-safe series:
/// Air Rifle (AR), Small Bore (SB), and the DCCT-only/indoor GP Rifle
/// practices. Where the document offers a genuine choice of firing position
/// ("Standing or Prone"), or a materially different standard depending on
/// the range/distance or DCCT fired, that entry is split into one catalog
/// entry per variant, each pre-filled with its own ACP-specified default —
/// still editable, since a local SOP may differ.
enum PracticeCatalog {
    struct Entry: Identifiable, Hashable {
        var id: String { name }
        let name: String
        let scoringType: ScoringType
        var defaultPassMark: Int?
        var defaultEsPassMark: Int?
        var defaultPvPassMark: Int?
    }

    static let entries: [Entry] = arEntries + sbEntries + gpEntries

    private static let arEntries: [Entry] = [
        Entry(name: "AR1 Grouping (5.5m)", scoringType: .standard, defaultPassMark: 22),
        Entry(name: "AR1 Grouping (10m)", scoringType: .standard, defaultPassMark: 39),
        Entry(name: "AR2 Grouping (Sitting, 5.5m)", scoringType: .standard, defaultPassMark: 19),
        Entry(name: "AR2 Grouping (Sitting, 10m)", scoringType: .standard, defaultPassMark: 35),
        Entry(name: "AR2 Grouping (Kneeling, 5.5m)", scoringType: .standard, defaultPassMark: 38),
        Entry(name: "AR2 Grouping (Kneeling, 10m)", scoringType: .standard, defaultPassMark: 69),
        // PV standard is "touching or within the inner scoring ring" — no plain mm figure given.
        Entry(name: "AR3 Zeroing (5.5m)", scoringType: .zeroing, defaultEsPassMark: 13),
        Entry(name: "AR3 Zeroing (10m)", scoringType: .zeroing, defaultEsPassMark: 23),
        Entry(name: "AR4.1 Deliberate (Prone)", scoringType: .points, defaultPassMark: 30),
        Entry(name: "AR4.2 Deliberate (Sitting)", scoringType: .points, defaultPassMark: 25),
        Entry(name: "AR4.3 Deliberate (Kneeling)", scoringType: .points, defaultPassMark: 20),
        Entry(name: "AR4.4 Deliberate (Standing)", scoringType: .points, defaultPassMark: 15),
        // AR5/AR6 score = hits achieved. ACP gives no fixed hit target for Sighting (5.1);
        // 5.2-5.4 and AR6 call for 5 hits, so 5 is the pass mark and more is still better.
        Entry(name: "AR5.1 Sighting (Standing)", scoringType: .points),
        Entry(name: "AR5.1 Sighting (Prone)", scoringType: .points),
        Entry(name: "AR5.2 Advance & Shoot (Standing)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR5.2 Advance & Shoot (Prone)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR5.3 Advance & Shoot 100m (Standing)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR5.3 Advance & Shoot 100m (Prone)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR5.4 Advance & Shoot 200/300m (Standing)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR5.4 Advance & Shoot 200/300m (Prone)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR6 Target Sprint (Standing)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR6 Target Sprint (Prone)", scoringType: .points, defaultPassMark: 5),
        Entry(name: "AR7.1 Snap (Prone)", scoringType: .points, defaultPassMark: 30),
        Entry(name: "AR7.2 Rapid (Prone)", scoringType: .points, defaultPassMark: 25),
        Entry(name: "AR7.3 Snap (Sitting)", scoringType: .points, defaultPassMark: 25),
        Entry(name: "AR7.4 Rapid (Sitting)", scoringType: .points, defaultPassMark: 20),
        Entry(name: "AR7.5 Snap (Kneeling)", scoringType: .points, defaultPassMark: 20),
        Entry(name: "AR7.6 Deliberate (Standing)", scoringType: .points, defaultPassMark: 15),
    ]

    private static let sbEntries: [Entry] = [
        Entry(name: "SB1 Grouping (25yd)", scoringType: .standard, defaultPassMark: 97),
        Entry(name: "SB1 Grouping (25m)", scoringType: .standard, defaultPassMark: 106),
        // Standard is a reduction relative to SB1's result, not a fixed figure.
        Entry(name: "SB2 Grouping Development", scoringType: .completion),
        // PV = ¼ of ES, rounded to the nearest mm.
        Entry(name: "SB3 Zeroing (25yd)", scoringType: .zeroing, defaultEsPassMark: 57, defaultPvPassMark: 14),
        Entry(name: "SB3 Zeroing (25m)", scoringType: .zeroing, defaultEsPassMark: 62, defaultPvPassMark: 16),
        Entry(name: "SB4 Deliberate", scoringType: .points, defaultPassMark: 140),
        Entry(name: "SB5.1 Snap", scoringType: .points, defaultPassMark: 35),
        Entry(name: "SB5.2 Rapid", scoringType: .points, defaultPassMark: 30),
    ]

    private static let gpEntries: [Entry] = [
        Entry(name: "GP1 DCCT Grouping (25m)", scoringType: .completion),
        Entry(name: "GP2 Grouping (25x)", scoringType: .standard, defaultPassMark: 102),
        Entry(name: "GP2 Grouping (DCCT)", scoringType: .standard, defaultPassMark: 85),
        Entry(name: "GP3 Grouping (Sitting, 25x)", scoringType: .standard, defaultPassMark: 90),
        Entry(name: "GP3 Grouping (Sitting, DCCT)", scoringType: .standard, defaultPassMark: 75),
        Entry(name: "GP3 Grouping (Kneeling, 25x)", scoringType: .standard, defaultPassMark: 180),
        Entry(name: "GP3 Grouping (Kneeling, DCCT)", scoringType: .standard, defaultPassMark: 150),
        Entry(name: "GP4 DCCT Grouping Consolidation", scoringType: .completion),
        Entry(name: "GP5 Zeroing (25m)", scoringType: .zeroing, defaultEsPassMark: 60, defaultPvPassMark: 13),
        Entry(name: "GP8 DCCT Apply Fire (100m)", scoringType: .completion),
        Entry(name: "GP11 DCCT Apply Fire (200-300m)", scoringType: .completion),
    ]
}
