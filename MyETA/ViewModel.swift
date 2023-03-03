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

    @Published var places: [Place] = [
        Place(
            name: "Amanda's House",
            street: "5250 Murdock",
            city: "St. Louis",
            state: "MO",
            country: "USA",
            postalCode: "63109"
        ),
        Place(
            name: "Home",
            street: "644 Glen Summit",
            city: "St. Charles",
            state: "MO",
            country: "USA",
            postalCode: "63304"
        )
    ]
}
