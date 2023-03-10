import Contacts
import SwiftUI

struct AddContact: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @State private var contact: CNContact?
    @State private var isFindingContact = false
    @State private var isShowingMessage = false
    @State private var message = ""

    private func contactChanged(_ contact: CNContact?) {
        guard let contact else { return }

        message = ""

        // Find the first "Mobile" phone number.
        let phone = contact.phoneNumbers.first { phoneNumber in
            guard let label = phoneNumber.label else { return false }
            return label.contains("Mobile")
        }

        var personID: UUID?

        // We only add a PersonEntity for contacts that have a mobile phone.
        // Presumably businesses do not have mobile phones,
        // and we do not want to add a PersonEntity for businesses.
        if let phone {
            // Add a PersonEntity in Core Data.
            let person = PersonEntity(context: moc)
            person.firstName = contact.givenName
            person.lastName = contact.familyName
            person.mobileNumber = phone.value.stringValue
            personID = UUID()
            person.id = personID

            let fullName = "\(contact.givenName) \(contact.familyName)"
            message = "Added person \"\(fullName)\""
        }

        // We only add a PlaceEntity for contacts that have a postal address.
        if let postalAddress = contact.postalAddresses.first {
            // Add a PlaceEntity in Core Data.
            let place = PlaceEntity(context: moc)
            let name = phone == nil ?
                contact.organizationName :
                "\(contact.givenName)'s house"
            place.name = name
            let address = postalAddress.value
            place.street = address.street
            place.city = address.city
            place.state = address.state
            place.country = address.country.isEmpty ? "USA" : address.country
            place.postalCode = address.postalCode
            place.id = UUID()
            if let personID { place.personID = personID }

            if message.isEmpty {
                message = "Added place \"\(name)\""
            } else {
                message += " and place \"\(name)\""
            }
        }

        // Save the new PersonEntity and PlaceEntity.
        save()

        // Display an alert that describes what was added.
        if !message.isEmpty {
            message += "."
            isShowingMessage = true
        }
    }

    private func save() {
        do {
            try moc.save()
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to save contact in Core Data."
            )
        }
    }

    var body: some View {
        Button("Add From Contacts") {
            isFindingContact = true
        }
        .buttonStyle(.bordered)
        .alert(
            "Added Contact",
            isPresented: $isShowingMessage,
            actions: {},
            message: { Text(message) }
        )
        .onChange(of: contact, perform: contactChanged)
        .sheet(isPresented: $isFindingContact) {
            ContactPicker(contact: $contact)
        }
    }
}
