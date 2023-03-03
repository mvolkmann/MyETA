import SwiftUI

struct PersonForm: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: ViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var cellNumber = ""
    @State private var firstName = ""
    @State private var index: Int?
    @State private var lastName = ""

    @Binding var person: Person

    private let textFieldWidth: CGFloat = 250

    private func labeledTextField(
        label: String,
        text: Binding<String>,
        focusedPath: KeyPath<PersonForm, String>
    ) -> some View {
        LabeledContent(label) {
            TextField("", text: text, onCommit: nextFocus)
                .frame(width: textFieldWidth)
                .focused($focus, equals: focusedPath)
                .autocorrectionDisabled(true)
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

    private var valid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && cellNumber.count >= 10
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
                let word = index == nil ? "Add" : "Update"
                Button("\(word) Person") {
                    let person = Person(
                        firstName: firstName,
                        lastName: lastName,
                        cellNumber: cellNumber
                    )
                    if let index {
                        vm.people[index] = person
                    } else {
                        vm.people.append(person)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!valid)

                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onAppear {
            firstName = person.firstName
            lastName = person.lastName
            cellNumber = person.cellNumber

            index = vm.people.firstIndex { p in p.id == person.id }

            focus = \Self.firstName // initial focus
        }
    }
}
