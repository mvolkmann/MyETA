import SwiftUI

struct AddPerson: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: ViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var cellNumber = ""

    let textFieldWidth: CGFloat = 250

    private var canAdd: Bool {
        !firstName.isEmpty && !lastName.isEmpty && cellNumber.count >= 10
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
        // TODO: Fix focus handling to move from field to field on return.
        VStack {
            LabeledContent("First Name") {
                TextField("first name", text: $firstName, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.firstName)
            }
            LabeledContent("Last Name") {
                TextField("last name", text: $lastName, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.lastName)
            }
            LabeledContent("Cell Number") {
                TextField("cell number", text: $cellNumber, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.cellNumber)
            }

            Button("Add Person") {
                vm.addPerson(Person(
                    firstName: firstName,
                    lastName: lastName,
                    cellNumber: cellNumber
                ))
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdd)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onAppear {
            focus = \Self.firstName // initial focus
        }
    }
}
