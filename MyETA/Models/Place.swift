struct Place: Hashable, Identifiable {
    let name: String
    let street: String
    let city: String
    let state: String
    let country: String
    let postalCode: String

    var id: String { street + "|" + postalCode }
}
