import CoreLocation
import SwiftUI

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationViewModel()

    @Published var error: Error?
    @Published var location: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        location = locations.first?.coordinate
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        self.error = error
    }
}

/*
 @Published var location = CLLocationCoordinate2D(
     // latitude: 38.7094263,
     // longitude: -90.5971701
     latitude: 38.5864931,
     longitude: -90.284247
 )
 */
