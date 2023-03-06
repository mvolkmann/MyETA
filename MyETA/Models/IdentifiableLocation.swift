import CoreLocation

struct IdentifiableLocation: Identifiable {
    let id = UUID()
    let location: CLLocationCoordinate2D

    init(_ location: CLLocationCoordinate2D) {
        self.location = location
    }
}
