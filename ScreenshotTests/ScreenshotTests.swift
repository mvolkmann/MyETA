import XCTest

final class ScreenshotTests: XCTestCase {
    let waitSeconds: TimeInterval = 5.0

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {}

    func peopleScreen() throws {
        tapTabBarButton(label: "people-tab", wait: waitSeconds)
        try textExists("People", wait: waitSeconds)
        snapshot("2-people")
    }

    func personSheet() throws {
        tapTabBarButton(label: "people-tab", wait: waitSeconds)
        tapButton(label: "add-person-button")
        try textExists("First Name", wait: waitSeconds)
        snapshot("3-person-sheet")
    }

    func placeSheet() throws {
        tapTabBarButton(label: "places-tab", wait: waitSeconds)
        tapButton(label: "add-place-button")
        try textExists("Postal Code", wait: waitSeconds)
        snapshot("5-place-sheet")
    }

    func placesScreen() throws {
        tapTabBarButton(label: "places-tab", wait: waitSeconds)
        try textExists("Places", wait: waitSeconds)
        snapshot("4-places")
    }

    func sendETAScreen() throws {
        tapTabBarButton(label: "send-tab", wait: waitSeconds)
        try textExists("Your Location", wait: waitSeconds)
        snapshot("1-send-eta")
    }

    func testScreenshots() throws {
        try sendETAScreen()
        try peopleScreen()
        try personSheet()
        try placesScreen()
        try placeSheet()
    }
}
