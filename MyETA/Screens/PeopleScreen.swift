import Contacts
import SwiftUI

struct PeopleScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
    ) var people: FetchedResults<PersonEntity>

    @State private var contact: CNContact?
    @State private var isActive = false
    @State private var isFindingContact = false
    @State private var isShowingForm = false
    @State private var isShowingMessage = false
    @State private var person: PersonEntity?
    @State private var message = ""

    private func contactChanged(_ contact: CNContact?) {
        guard let contact else { return }

        message = ""

        // Find the first "Mobile" phone number.
        let phone = contact.phoneNumbers.first { phoneNumber in
            guard let label = phoneNumber.label else { return false }
            return label.contains("Mobile")
        }

        // We only add a PersonEntity for contacts that have a mobile phone.
        // Presumably businesses do not have mobile phones,
        // and we do not want to add a PersonEntity for businesses.
        if let phone {
            // Add a PersonEntity in Core Data.
            let person = PersonEntity(context: moc)
            person.firstName = contact.givenName
            person.lastName = contact.familyName
            person.mobileNumber = phone.value.stringValue

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

    private func deletePerson(at indexSet: IndexSet) {
        for index in indexSet {
            moc.delete(people[index])
        }
        save()
    }

    private func personRow(_ person: PersonEntity) -> some View {
        let firstName = person.firstName ?? ""
        let lastName = person.lastName ?? ""
        return Text("\(firstName) \(lastName)")
            .onTapGesture {
                self.person = person
                isShowingForm = true
            }
    }

    private func save() {
        do {
            try moc.save()
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to save people change to Core Data."
            )
        }
    }

    var body: some View {
        ZStack {
            let fill = gradient(colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

            VStack {
                Button("Add From Contacts") {
                    isFindingContact = true
                }
                .buttonStyle(.bordered)

                if !people.isEmpty {
                    // editActions doesn't work with CoreData models.
                    // List($vm.people, editActions: .all) { $person in
                    List {
                        ForEach(people) { person in
                            personRow(person)
                        }
                        .onDelete(perform: deletePerson)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden) // hides default background
                }

                Spacer()
            }
            .padding()
        }
        .alert(
            "Added Contact",
            isPresented: $isShowingMessage,
            actions: {},
            message: { Text(message) }
        )
        .onAppear { isActive = true }
        .onChange(of: contact, perform: contactChanged)
        .onDisappear { isActive = false }
        .sheet(isPresented: $isFindingContact) {
            ContactPicker(contact: $contact)
        }
        .sheet(isPresented: $isShowingForm) {
            PersonForm(person: $person)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
        .toolbar {
            if isActive {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        person = nil
                        isShowingForm = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("add-person-button")
                }
            }
        }
    }
}
