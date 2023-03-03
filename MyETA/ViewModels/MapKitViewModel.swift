import MapKit // This imports CoreLocation.
import SwiftUI

// Add this key in the Info tab for each target that queries current location:
// Privacy - Location When In Use Usage Description
final class MapKitViewModel: NSObject, ObservableObject {
    // MARK: - State

    @Published var message: String?

    @Published var searchLocations: [String] = []
    @Published var searchQuery = ""
    @Published var selectedPlace: Place?
    @Published var selectedPlacemark: CLPlacemark?

    // MARK: - Properties

    static var shared = MapKitViewModel()

    private let completer = MKLocalSearchCompleter()
    private let locationManager = CLLocationManager()

    // MARK: - Initializer

    override init() {
        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()

        // A new query is started automatically when searchQuery changes.
        _ = $searchQuery.assign(to: \.queryFragment, on: completer)
    }

    // MARK: - Methods

    func travelTime(to: CLPlacemark) async throws -> TimeInterval {
        // TODO: Will this get a new current location every time this is called?
        guard let fromLocation = locationManager.location else {
            throw "failed to get current location"
        }

        guard let toLocation = to.location else {
            throw "failed to get destination location"
        }

        guard let endCLPlacemark = try await CoreLocationService.getPlacemark(
            from: toLocation
        ) else {
            throw "failed to get destination placemark"
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: fromLocation.coordinate)
        )
        request.destination = MKMapItem(
            placemark: MKPlacemark(placemark: endCLPlacemark)
        )
        request.transportType = .automobile

        // Get multiple options so we can choose the shortest route.
        // It seems when only one is returned it isn't always the shortest.
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        // Sort the routes from shortest to longest travel time.
        var routes = response.routes
        routes.sort { $0.expectedTravelTime < $1.expectedTravelTime }

        guard let route = routes.first else {
            throw "failed to find a route"
        }

        return route.expectedTravelTime
    }
}
