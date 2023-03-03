import SwiftUI

struct PersonForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var vm: ViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var cellNumber = ""
    @State private var errorMessage: String?
    @State private var firstName = ""
    @State private var index: Int?
    @State private var lastName = ""

    @Binding var person: PersonEntity?

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

    private func save() {
        do {
            try moc.save()
            errorMessage = nil
        } catch {
            Log.error(error)
            errorMessage = error.localizedDescription
        }
    }

    private var valid: Bool {
        // !firstName.isEmpty && !lastName.isEmpty && cellNumber.count >= 10
        !firstName.isEmpty && !lastName.isEmpty && !cellNumber.isEmpty
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
                let adding = person == nil
                let word = adding ? "Add" : "Update"
                Button("\(word) Person") {
                    if adding {
                        person = PersonEntity(context: moc)
                    }
                    if let person {
                        person.firstName = firstName
                        person.lastName = lastName
                        person.cellNumber = cellNumber
                        person.id = UUID()
                        save()
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!valid)

                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
            }

            if let errorMessage {
                Text(errorMessage)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onAppear {
            firstName = person?.firstName ?? ""
            lastName = person?.lastName ?? ""
            cellNumber = person?.cellNumber ?? ""

            focus = \Self.firstName // initial focus
        }
    }
}
