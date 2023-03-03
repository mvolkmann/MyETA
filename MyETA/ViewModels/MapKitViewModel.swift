import Combine // for AnyCancellable
import MapKit // This imports CoreLocation.
import SwiftUI

// Add this key in the Info tab for each target that queries current location:
// Privacy - Location When In Use Usage Description
final class MapKitViewModel: NSObject, ObservableObject {
    // MARK: - Constants

    private static let defaultDistance = 1000.0 // in meters

    // MARK: - State

    // These four properties define what the map will display.
    @Published var center: CLLocationCoordinate2D?
    @Published var distance = 0.0 // changed in initializer

    @Published var currentPlacemark: CLPlacemark?
    @Published var message: String?

    @Published var searchLocations: [String] = []
    @Published var searchQuery = ""
    @Published var selectedPlace: Place?
    @Published var selectedPlacemark: CLPlacemark?
    @Published var travelSeconds: TimeInterval = 0.0

    static var shared = MapKitViewModel()

    // MARK: - Initializer

    override init() {
        // This must precede the call to super.init.
        completer = MKLocalSearchCompleter()

        super.init()

        distance = Self.defaultDistance

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        // A new query is started automatically when searchQuery changes.
        cancellable = $searchQuery.assign(to: \.queryFragment, on: completer)

        // This cannot precede the call to super.init.
        completer.delegate = self

        // This specifies the types of search completions to include.
        // Perhaps all are included if this is not specified.
        // completer.resultTypes = [.address, .pointOfInterest, .query]
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

        if let route = routes.first {
            return route.expectedTravelTime
        } else {
            return 0 // couldn't determine
        }
    }

    // This is called by ContentView.
    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

// This is used to get the current user location.
extension MapKitViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        // If we already have the placemark, return.
        guard currentPlacemark == nil else { return }

        if let location = locations.first {
            center = location.coordinate
            CLGeocoder().reverseGeocodeLocation(
                location
            ) { [weak self] placemarks, error in
                if let error {
                    Log.error(error)
                } else if let self {
                    self.currentPlacemark = placemarks?.first
                    self.selectedPlacemark = self.currentPlacemark
                    // Once we have the location, stop trying to update it.
                    self.locationManager.stopUpdatingLocation()
                }
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        Log.error("failed to get current location; user may not have approved")
        // If the user denies sharing location, to approve it they must:
        // 1. Open the Settings app.
        // 2. Go to Privacy ... Location Services.
        // 3. Tap the name of this app.
        // 4. Change the option from "Never" to
        //    "Ask Next Time" or "While Using the App".
    }
}

extension MapKitViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var locations = completer.results.map { result in
            let title = result.title
            let subtitle = result.subtitle
            return subtitle.isEmpty ? title : title + ", " + subtitle
        }
        locations.sort()
        searchLocations = locations
    }
}
