import SwiftUI

struct PeopleScreen: View {
    @EnvironmentObject private var vm: ViewModel

    @State private var isAdding = false

    private func personRow(_ person: Person) -> some View {
        Text("\(person.firstName) \(person.lastName)")
    }

    var body: some View {
        VStack {
            HStack {
                Text("People").font(.largeTitle)
                Button(action: { isAdding = true }) {
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
        .sheet(isPresented: $isAdding) {
            AddPerson()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}
