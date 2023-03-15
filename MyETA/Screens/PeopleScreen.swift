import SwiftUI

struct PeopleScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                key: "lastName",
                ascending: true,
                selector: #selector(NSString.localizedStandardCompare)
            ),
            NSSortDescriptor(
                key: "firstName",
                ascending: true,
                selector: #selector(NSString.localizedStandardCompare)
            )
        ]
    ) var people: FetchedResults<PersonEntity>

    @State private var isFindingContact = false
    @State private var isShowingForm = false
    @State private var isShowingMessage = false
    @State private var person: PersonEntity?
    @State private var message = ""

    private var buttons: some View {
        HStack {
            AddContact()

            Button("Add Manually") {
                person = nil
                isShowingForm = true
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("add-person-button")
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
                message: "Failed to save people change in Core Data."
            )
        }
    }

    var body: some View {
        ZStack {
            let fill = gradient(colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

            VStack {
                buttons

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
        .sheet(isPresented: $isShowingForm) {
            PersonForm(person: $person)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}
