import SwiftUI

// TODO: Persist this data using CoreData or CloudKit.
class ViewModel: ObservableObject {
    @Published var people: [Person] = [
        Person(
            firstName: "Tami",
            lastName: "Volkmann",
            cellNumber: "314-398-6256"
        ),
        Person(
            firstName: "Mark",
            lastName: "Volkmann",
            cellNumber: "314-398-6537"
        )
    ]

    @Published var places: [Place] = []

    func addPerson(_ person: Person) {
        people.append(person)
    }
}
