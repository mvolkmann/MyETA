import SwiftUI

struct PersonForm: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var mobileNumber = ""
    @State private var firstName = ""
    @State private var index: Int?
    @State private var lastName = ""

    @Binding var person: PersonEntity?

    private let textFieldWidth: CGFloat = 250

    private var buttonsView: some View {
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
                    person.mobileNumber = mobileNumber
                    person.id = UUID()
                    save()
                }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!valid)
            .accessibilityIdentifier("add-button")

            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("cancel-button")
        }
    }

    private var fieldsView: some View {
        Group {
            labeledTextField(
                label: "First Name *",
                text: $firstName,
                focusedPath: \Self.firstName,
                identifier: "first-name-text-field"
            )
            labeledTextField(
                label: "Last Name",
                text: $lastName,
                focusedPath: \Self.lastName,
                identifier: "last-name-text-field"
            )
            labeledTextField(
                label: "Mobile Number *",
                text: $mobileNumber,
                focusedPath: \Self.mobileNumber,
                identifier: "mobile-number-text-field"
            )
            .numbersOnly($mobileNumber)
        }
        .textFieldStyle(.roundedBorder)
    }

    private func labeledTextField(
        label: String,
        text: Binding<String>,
        focusedPath: KeyPath<PersonForm, String>,
        identifier: String
    ) -> some View {
        LabeledContent(label) {
            TextField("", text: text, onCommit: nextFocus)
                .frame(width: textFieldWidth)
                .focused($focus, equals: focusedPath)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier(identifier)
        }
    }

    private func nextFocus() {
        switch focus {
        case \Self.firstName: focus = \Self.lastName
        case \Self.lastName: focus = \Self.mobileNumber
        case \Self.mobileNumber: focus = \Self.firstName
        default: break
        }
    }

    private func save() {
        do {
            try moc.save()
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to save person to Core Data."
            )
        }
    }

    private var valid: Bool {
        !firstName.isEmpty && mobileNumber.count >= 10
    }

    var body: some View {
        // A NavigationView is required in order for
        // the keyboard toolbar button to appear and work.
        NavigationView {
            ZStack {
                let fill = gradient(.orange, colorScheme: colorScheme)
                Rectangle().fill(fill).ignoresSafeArea()

                VStack {
                    fieldsView

                    buttonsView

                    Spacer()
                }
                .padding()
                .padding(.top)
                .onAppear {
                    firstName = person?.firstName ?? ""
                    lastName = person?.lastName ?? ""
                    mobileNumber = person?.mobileNumber ?? ""
                    focus = \Self.firstName // initial focus
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button(action: dismissKeyboard) {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                }
            }
        }
    }
}
