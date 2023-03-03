import Foundation

struct Person: Hashable, Identifiable {
    var firstName: String
    var lastName: String
    var cellNumber: String

    let id = UUID()
}
