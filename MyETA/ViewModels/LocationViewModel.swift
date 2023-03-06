import CoreLocation

// This was inspired by the Hacking With Swift post at
// https://www.hackingwithswift.com/quick-start/swiftui/how-to-read-the-users-location-using-locationbutton
class LocationViewModel: NSObject, CLLocationManagerDelegate, ObservableObject {
    let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()

        manager.delegate = self

        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("\(#fileID) \(#function) error:", error)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        location = locations.first?.coordinate
    }
}
