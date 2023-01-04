import XCTest

class SwiftTests: XCTestCase {
    func fizzbuzz(i: Int) -> String {
        if (i % 3 == 0) {
            if (i % 5 == 0) {
                return "FizzBuzz";
            }
            return "Fizz";
        }
        if (i % 5 == 0) {
            return "Buzz";
        }
        return String(i);
    }

    func test() {
        XCTAssertEqual(fizzbuzz(i: 1), "1")
        XCTAssertEqual(fizzbuzz(i: 2), "2")
        XCTAssertEqual(fizzbuzz(i: 3), "Fizz")
        XCTAssertEqual(fizzbuzz(i: 4), "4")
        XCTAssertEqual(fizzbuzz(i: 5), "Buzz")
        XCTAssertEqual(fizzbuzz(i: 15), "FizzBuzz")
    }

    static var allTests = [
        ("test", test),
    ]
}
