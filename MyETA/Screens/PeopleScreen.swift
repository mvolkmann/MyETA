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

    @State private var isActive = false
    @State private var isFindingContact = false
    @State private var isShowingForm = false
    @State private var isShowingMessage = false
    @State private var person: PersonEntity?
    @State private var message = ""

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
                AddContact()

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
        .onDisappear { isActive = false }
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
