import XCTest

class HelloAppUITest: XCTestCase {
    var application: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        application = .init()
        application.launch()
    }

    override func tearDown() {
        application.terminate()
        application = nil
    }

    func testIsActive() {
        Thread.sleep(forTimeInterval: 120.0)
        XCTAssertTrue(application.staticTexts["HELLO_WORLD"].exists)
    }
}

