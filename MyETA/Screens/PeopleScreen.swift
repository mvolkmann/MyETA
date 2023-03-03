import SwiftUI

struct PeopleScreen: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
    ) var people: FetchedResults<PersonEntity>

    @State private var errorMessage: String?
    @State private var isShowingForm = false
    @State private var person: PersonEntity?

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
            errorMessage = nil
        } catch {
            Log.error(error)
            errorMessage = error.localizedDescription
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("People").font(.largeTitle)
                Button(action: {
                    person = nil
                    isShowingForm = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            // editActions doesn't work with CoreData models.
            // List($vm.people, editActions: .all) { $person in
            List {
                ForEach(people) { person in
                    personRow(person)
                }
                .onDelete(perform: deletePerson)
            }
            .listStyle(.grouped)
        }
        .padding()
        .sheet(isPresented: $isShowingForm) {
            PersonForm(person: $person)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}
