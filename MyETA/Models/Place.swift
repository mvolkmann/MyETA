import CoreLocation // for CLLocationCoordinate2D
import Foundation

struct Place: Hashable, Identifiable {
    let name: String
    let street: String
    let city: String
    let state: String
    let country: String
    let postalCode: String

    let coordinate: CLLocationCoordinate2D

    let id: UUID

    init(
        name: String,
        street: String,
        city: String,
        state: String,
        country: String,
        postalCode: String
    ) {
        self.name = name
        self.street = street
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode

        coordinate = CLLocationCoordinate2D()

        id = UUID()
    }
}
