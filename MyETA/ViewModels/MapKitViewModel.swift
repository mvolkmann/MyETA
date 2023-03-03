import Combine // for AnyCancellable
import MapKit // This imports CoreLocation.
import SwiftUI

// Add this key in the Info tab for each target that queries current location:
// Privacy - Location When In Use Usage Description
final class MapKitViewModel: NSObject, ObservableObject {
    // MARK: - Constants

    private static let defaultDistance = 1000.0 // in meters

    // MARK: - State

    @Published var message: String?

    @Published var searchLocations: [String] = []
    @Published var searchQuery = ""
    @Published var selectedPlace: Place?
    @Published var selectedPlacemark: CLPlacemark?

    static var shared = MapKitViewModel()

    // MARK: - Initializer

    override init() {
        // This must precede the call to super.init.
        completer = MKLocalSearchCompleter()

        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // A new query is started automatically when searchQuery changes.
        cancellable = $searchQuery.assign(to: \.queryFragment, on: completer)
    }

    // MARK: - Properties

    // This can be used to cancel an active search, but we aren't using it.
    private var cancellable: AnyCancellable?

    private var completer: MKLocalSearchCompleter

    private let locationManager = CLLocationManager()

    // MARK: - Methods

    func travelTime(to: CLPlacemark) async throws -> TimeInterval {
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
        let endPlacemark = MKPlacemark(placemark: endCLPlacemark)

        let startPlacemark = MKPlacemark(coordinate: fromLocation.coordinate)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
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

    // This is called by ContentView.
    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}
