import XCTest

final class ScreenshotTests: XCTestCase {
    let firstName = "Mark"
    let lastName = "Volkmann"
    let placeName = "Work"
    let waitSeconds: TimeInterval = 5.0

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {}

    func addPerson() {
        tapTabBarButton(label: "people-tab", wait: waitSeconds)

        // Delete existing person.
        let fullName = "\(firstName) \(lastName)"
        let element = Self.app.staticTexts[fullName]
        if element.exists {
            element.swipeLeft()
            tapButton(label: "Delete")
        }

        tapButton(label: "add-person-button")
        enterText(label: "first-name-text-field", text: firstName)
        enterText(label: "last-name-text-field", text: lastName)
        enterText(label: "cell-number-text-field", text: "1234567890")
        tapButton(label: "add-button")
    }

    func addPlace() {
        tapTabBarButton(label: "places-tab", wait: waitSeconds)

        // Delete existing place.
        let element = Self.app.staticTexts[placeName]
        if element.exists {
            element.swipeLeft()
            tapButton(label: "Delete")
        }

        tapButton(label: "add-place-button")
        enterText(label: "name-text-field", text: placeName)
        enterText(
            label: "street-text-field",
            text: "12140 Woodcrest Executive Drive"
        )
        enterText(label: "city-text-field", text: "Creve Coeur")
        enterText(label: "state-text-field", text: "MO")
        enterText(label: "country-text-field", text: "USA")
        enterText(label: "postal-code-text-field", text: "63141")
        tapButton(label: "add-button")
    }

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
        tapButton(label: "cancel-button")
    }

    func placeSheet() throws {
        tapTabBarButton(label: "places-tab", wait: waitSeconds)
        tapButton(label: "add-place-button")
        try textExists("Postal Code", wait: waitSeconds)
        snapshot("5-place-sheet")
        tapButton(label: "cancel-button")
    }

    func placesScreen() throws {
        tapTabBarButton(label: "places-tab", wait: waitSeconds)
        try textExists("Places", wait: waitSeconds)
        snapshot("4-places")
    }

    func sendETAScreen() throws {
        tapTabBarButton(label: "send-eta-tab", wait: waitSeconds)
        try textExists("Your Location", wait: waitSeconds)
        snapshot("1-send-eta")
    }

    func testScreenshots() throws {
        addPerson()
        addPlace()
        try sendETAScreen()
        try peopleScreen()
        try personSheet()
        try placesScreen()
        try placeSheet()
    }
}
