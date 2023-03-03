import SwiftUI

struct PeopleScreen: View {
    @EnvironmentObject private var vm: ViewModel

    @State private var isAdding = false
    @State private var isShowingForm = false
    @State private var person = Person(
        firstName: "",
        lastName: "",
        cellNumber: ""
    )

    private func personRow(_ person: Person) -> some View {
        Text("\(person.firstName) \(person.lastName)")
            .onTapGesture {
                print("\(#fileID) \(#function) person =", person)
                self.person = person
                isAdding = false
                isShowingForm = true
            }
    }

    var body: some View {
        VStack {
            HStack {
                Text("People").font(.largeTitle)
                Button(action: {
                    isAdding = true
                    isShowingForm = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                }
            }

            List($vm.people, editActions: .all) { $person in
                personRow(person)
            }
            .listStyle(.grouped)
        }
        .padding()
        .sheet(isPresented: $isShowingForm) {
            PersonForm(person: $person, isAdding: $isAdding)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}
