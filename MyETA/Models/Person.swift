import Foundation

struct Person: Hashable, Identifiable {
    var firstName: String
    var lastName: String
    var mobileNumber: String

    let id = UUID()
}
