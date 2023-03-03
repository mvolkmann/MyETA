import SwiftUI

struct PersonForm: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: ViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var cellNumber = ""

    var person: Binding<Person>
    let isAdding: Binding<Bool>

    private let textFieldWidth: CGFloat = 250

    private var canAdd: Bool {
        !firstName.isEmpty && !lastName.isEmpty && cellNumber.count >= 10
    }

    private func labeledTextField(
        label: String,
        text: Binding<String>,
        focusedPath: KeyPath<PersonForm, String>
    ) -> some View {
        LabeledContent(label) {
            TextField("", text: text, onCommit: nextFocus)
                .frame(width: textFieldWidth)
                .focused($focus, equals: focusedPath)
        }
    }

    private func nextFocus() {
        switch focus {
        case \Self.firstName: focus = \Self.lastName
        case \Self.lastName: focus = \Self.cellNumber
        case \Self.cellNumber: focus = \Self.firstName
        default: break
        }
    }

    var body: some View {
        VStack {
            labeledTextField(
                label: "First Name",
                text: $firstName,
                focusedPath: \Self.firstName
            )
            labeledTextField(
                label: "Last Name",
                text: $lastName,
                focusedPath: \Self.lastName
            )
            labeledTextField(
                label: "Cell Number",
                text: $cellNumber,
                focusedPath: \Self.cellNumber
            )

            HStack {
                let word = isAdding.wrappedValue ? "Add" : "Update"
                Button("\(word) Person") {
                    vm.addPerson(Person(
                        firstName: firstName,
                        lastName: lastName,
                        cellNumber: cellNumber
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdd)

                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onAppear {
            print("\(#fileID) \(#function) person =", person)
            firstName = person.wrappedValue.firstName
            lastName = person.wrappedValue.lastName
            cellNumber = person.wrappedValue.cellNumber

            focus = \Self.firstName // initial focus
        }
    }
}
