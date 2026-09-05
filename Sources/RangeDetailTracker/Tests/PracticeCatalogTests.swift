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

    func testGP3IsSplitIntoSittingAndKneeling() {
        let names = Set(PracticeCatalog.entries.map(\.name))
        XCTAssertTrue(names.contains("GP3 Grouping (Sitting)"))
        XCTAssertTrue(names.contains("GP3 Grouping (Kneeling)"))
        XCTAssertFalse(names.contains { $0.contains("GP3") && $0.contains("Sit/Kneel") })
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
        ("testGP3IsSplitIntoSittingAndKneeling", testGP3IsSplitIntoSittingAndKneeling),
        ("testDistanceVariantsHaveTheirOwnACPDefault", testDistanceVariantsHaveTheirOwnACPDefault),
    ]
}
