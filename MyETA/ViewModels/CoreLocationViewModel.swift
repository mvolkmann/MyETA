import CoreLocation
import SwiftUI

// TODO: Do you need this file?
class CoreLocationViewModel: NSObject, ObservableObject,
    CLLocationManagerDelegate {
    @Published var error: Error?
    @Published var location: CLLocationCoordinate2D?

    let manager = CLLocationManager()

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
