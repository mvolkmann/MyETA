import SwiftUI

struct PersonRow: View {
    var person: Person

    var body: some View {
        Text("\(person.firstName) \(person.lastName)")
    }
}

struct PeopleScreen: View {
    @EnvironmentObject private var vm: ViewModel

    @State private var isAdding = false

    private var isFocused: FocusState<Bool>.Binding

    init(isFocused: FocusState<Bool>.Binding) {
        self.isFocused = isFocused
    }

    var body: some View {
        VStack {
            HStack {
                Text("People").font(.largeTitle)
                Button(action: { isAdding = true }) {
                    Image(systemName: "plus.circle.fill")
                        // .imageScale(.large)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                }
            }

            List($vm.people, editActions: .all) { $person in
                PersonRow(person: person)
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
