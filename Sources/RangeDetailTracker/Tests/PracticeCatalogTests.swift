final class PracticeCatalogTests: XCTestCase {
    func testCatalogIsNotEmpty() {
        XCTAssertTrue(!PracticeCatalog.entries.isEmpty)
    }

    func testCatalogNamesAreUnique() {
        let names = PracticeCatalog.entries.map(\.name)
        XCTAssertEqual(names.count, Set(names).count)
    }

    func testCatalogCoversAllThreeWeaponSeries() {
        let names = PracticeCatalog.entries.map(\.name)
        XCTAssertTrue(names.contains { $0.hasPrefix("AR") })
        XCTAssertTrue(names.contains { $0.hasPrefix("SB") })
        XCTAssertTrue(names.contains { $0.hasPrefix("GP") })
    }

    func testGP3IsSplitByPositionAndByRangeType() {
        let names = Set(PracticeCatalog.entries.map(\.name))
        XCTAssertTrue(names.contains("GP3 Grouping (Sitting, 25x)"))
        XCTAssertTrue(names.contains("GP3 Grouping (Sitting, DCCT)"))
        XCTAssertTrue(names.contains("GP3 Grouping (Kneeling, 25x)"))
        XCTAssertTrue(names.contains("GP3 Grouping (Kneeling, DCCT)"))
    }

    func testGP4IsIncluded() {
        let names = Set(PracticeCatalog.entries.map(\.name))
        XCTAssertTrue(names.contains("GP4 DCCT Grouping Consolidation"))
    }

    func testAR2HasDistinctStandardsPerPosition() {
        func entry(_ name: String) -> PracticeCatalog.Entry? {
            PracticeCatalog.entries.first { $0.name == name }
        }
        XCTAssertEqual(entry("AR2 Grouping (Sitting, 5.5m)")?.defaultPassMark, 19)
        XCTAssertEqual(entry("AR2 Grouping (Kneeling, 5.5m)")?.defaultPassMark, 38)
    }

    func testAR5And6HitsTargetIsFiveAndNotOnSighting() {
        func entry(_ name: String) -> PracticeCatalog.Entry? {
            PracticeCatalog.entries.first { $0.name == name }
        }
        XCTAssertEqual(entry("AR5.2 Advance & Shoot (Standing)")?.defaultPassMark, 5)
        XCTAssertEqual(entry("AR5.3 Advance & Shoot 100m (Prone)")?.defaultPassMark, 5)
        XCTAssertEqual(entry("AR5.4 Advance & Shoot 200/300m (Prone)")?.defaultPassMark, 5)
        XCTAssertEqual(entry("AR6 Target Sprint (Standing)")?.defaultPassMark, 5)
        XCTAssertNil(entry("AR5.1 Sighting (Standing)")?.defaultPassMark)
    }

    func testSB1And3OnlyKeep25ydAnd25mDistances() {
        let names = Set(PracticeCatalog.entries.map(\.name))
        XCTAssertFalse(names.contains { $0.hasPrefix("SB1") && ($0.contains("15x") || $0.contains("20x")) })
        XCTAssertFalse(names.contains { $0.hasPrefix("SB3") && ($0.contains("15x") || $0.contains("20x")) })
        XCTAssertTrue(names.contains("SB1 Grouping (25yd)"))
        XCTAssertTrue(names.contains("SB1 Grouping (25m)"))
    }

    func testSB6IsRemoved() {
        let names = Set(PracticeCatalog.entries.map(\.name))
        XCTAssertFalse(names.contains { $0.hasPrefix("SB6") })
    }

    func testSB7IsRemoved() {
        let names = Set(PracticeCatalog.entries.map(\.name))
        XCTAssertFalse(names.contains { $0.hasPrefix("SB7") })
    }

    func testDistanceVariantsHaveTheirOwnACPDefault() {
        func entry(_ name: String) -> PracticeCatalog.Entry? {
            PracticeCatalog.entries.first { $0.name == name }
        }
        XCTAssertEqual(entry("AR1 Grouping (5.5m)")?.defaultPassMark, 22)
        XCTAssertEqual(entry("AR1 Grouping (10m)")?.defaultPassMark, 39)
        XCTAssertEqual(entry("SB1 Grouping (25m)")?.defaultPassMark, 106)
        XCTAssertEqual(entry("GP2 Grouping (25x)")?.defaultPassMark, 102)
        XCTAssertEqual(entry("GP2 Grouping (DCCT)")?.defaultPassMark, 85)
        XCTAssertEqual(entry("GP5 Zeroing (25m)")?.defaultEsPassMark, 60)
        XCTAssertEqual(entry("GP5 Zeroing (25m)")?.defaultPvPassMark, 13)
    }

    static let allTests: [(String, (PracticeCatalogTests) -> () throws -> Void)] = [
        ("testCatalogIsNotEmpty", testCatalogIsNotEmpty),
        ("testCatalogNamesAreUnique", testCatalogNamesAreUnique),
        ("testCatalogCoversAllThreeWeaponSeries", testCatalogCoversAllThreeWeaponSeries),
        ("testGP3IsSplitByPositionAndByRangeType", testGP3IsSplitByPositionAndByRangeType),
        ("testGP4IsIncluded", testGP4IsIncluded),
        ("testAR2HasDistinctStandardsPerPosition", testAR2HasDistinctStandardsPerPosition),
        ("testAR5And6HitsTargetIsFiveAndNotOnSighting", testAR5And6HitsTargetIsFiveAndNotOnSighting),
        ("testSB1And3OnlyKeep25ydAnd25mDistances", testSB1And3OnlyKeep25ydAnd25mDistances),
        ("testSB6IsRemoved", testSB6IsRemoved),
        ("testSB7IsRemoved", testSB7IsRemoved),
        ("testDistanceVariantsHaveTheirOwnACPDefault", testDistanceVariantsHaveTheirOwnACPDefault),
    ]
}
