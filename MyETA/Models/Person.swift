struct Person: Identifiable {
    let firstName: String
    let lastName: String
    let cellNumber: String

    var id: String { cellNumber }
}
