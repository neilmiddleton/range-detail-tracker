import Foundation

open class XCTestCase {
    public required init() {}
}

public struct TestFailure: Error, CustomStringConvertible {
    public let message: String
    public var description: String { message }
}

func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    let (av, bv) = (a(), b())
    if av != bv {
        TestRunner.shared.recordFailure("XCTAssertEqual failed: \(av) != \(bv). \(message)", file: file, line: line)
    }
}

func XCTAssertNil(_ a: @autoclosure () -> Any?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if a() != nil {
        TestRunner.shared.recordFailure("XCTAssertNil failed. \(message)", file: file, line: line)
    }
}

func XCTAssertNotNil(_ a: @autoclosure () -> Any?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if a() == nil {
        TestRunner.shared.recordFailure("XCTAssertNotNil failed. \(message)", file: file, line: line)
    }
}

func XCTAssertTrue(_ a: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if !a() {
        TestRunner.shared.recordFailure("XCTAssertTrue failed. \(message)", file: file, line: line)
    }
}

func XCTAssertFalse(_ a: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if a() {
        TestRunner.shared.recordFailure("XCTAssertFalse failed. \(message)", file: file, line: line)
    }
}

func XCTUnwrap<T>(_ a: T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws -> T {
    guard let a else {
        TestRunner.shared.recordFailure("XCTUnwrap failed. \(message)", file: file, line: line)
        throw TestFailure(message: "XCTUnwrap failed")
    }
    return a
}

final class TestRunner {
    static let shared = TestRunner()
    private var failureCount = 0
    private var testCount = 0

    func recordFailure(_ message: String, file: StaticString, line: UInt) {
        failureCount += 1
        print("FAIL: \(message) (\(file):\(line))")
    }

    func run(_ name: String, _ body: () throws -> Void) {
        testCount += 1
        do {
            try body()
        } catch {
            failureCount += 1
            print("FAIL: \(name) threw: \(error)")
        }
    }

    func finish() -> Never {
        print("\n\(testCount) tests run, \(failureCount) assertion failures")
        exit(failureCount == 0 ? 0 : 1)
    }
}
