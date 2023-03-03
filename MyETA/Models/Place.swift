import Foundation

struct Place: Hashable, Identifiable {
    let name: String
    let street: String
    let city: String
    let state: String
    let country: String
    let postalCode: String

    let id = UUID()
}
