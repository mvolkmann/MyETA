import CoreLocation

struct IdentifiableLocation: Identifiable {
    let id: UUID
    let location: CLLocationCoordinate2D

    init(id: UUID = UUID(), location: CLLocationCoordinate2D) {
        self.id = id
        self.location = location
    }
}
