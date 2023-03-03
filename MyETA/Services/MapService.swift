import CoreLocation
import MapKit

struct MapService {
    static func getPlacemark(
        from location: CLLocation
    ) async throws -> CLPlacemark? {
        // Cannot call this more than 50 times per second.
        let placemarks = try await CLGeocoder()
            .reverseGeocodeLocation(location)
        if let placemark = placemarks.first {
            return placemark
        } else {
            throw "no placemarks found for \(location)"
        }
    }

    static func getPlacemark(
        from addressString: String
    ) async throws -> CLPlacemark {
        // Cannot call this more than 50 times per second.
        let placemarks = try await CLGeocoder()
            .geocodeAddressString(addressString)
        if let placemark = placemarks.first {
            return placemark
        } else {
            throw "no placemarks found for \(addressString)"
        }
    }

    static func travelTime(to: CLPlacemark) async throws -> TimeInterval {
        // Get the current location.
        // TODO: Will this get a new current location every time this is called?
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        guard let fromLocation = locationManager.location else {
            throw "failed to get current location"
        }

        // Get the destination placemark.
        guard let toLocation = to.location else {
            throw "failed to get destination location"
        }
        guard let endCLPlacemark = try await Self.getPlacemark(
            from: toLocation
        ) else {
            throw "failed to get destination placemark"
        }

        // Get driving route options.

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