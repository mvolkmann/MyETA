import Contacts
import SwiftUI

struct PersonForm: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var cellNumber = ""
    @State private var contact: CNContact?
    @State private var firstName = ""
    @State private var index: Int?
    @State private var isFindingContact = false
    @State private var lastName = ""

    @Binding var person: PersonEntity?

    private let textFieldWidth: CGFloat = 250

    private var buttonsView: some View {
        HStack {
            let adding = person == nil
            let word = adding ? "Add" : "Update"
            Button("\(word) Person") {
                print("got button tap; adding =", adding)
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
            // TODO: Why isn't this being evaluated immediately after selecting a contact with ContactPicker?
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
                label: "Cell Number *",
                text: $cellNumber,
                focusedPath: \Self.cellNumber,
                identifier: "cell-number-text-field"
            )
            .numbersOnly($cellNumber)
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
        case \Self.lastName: focus = \Self.cellNumber
        case \Self.cellNumber: focus = \Self.firstName
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
        !firstName.isEmpty && cellNumber.count >= 10
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

                    Button("Find in Contacts") {
                        isFindingContact = true
                    }
                    .buttonStyle(.borderedProminent)

                    buttonsView

                    Spacer()
                }
                .padding()
                .padding(.top)
                .onAppear {
                    firstName = person?.firstName ?? ""
                    lastName = person?.lastName ?? ""
                    cellNumber = person?.cellNumber ?? ""
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
        .onChange(of: contact) { _ in
            guard let contact else { return }
            firstName = contact.givenName
            lastName = contact.familyName

            // Find the first "Mobile" phone number.
            var phone = contact.phoneNumbers.first { phoneNumber in
                guard let label = phoneNumber.label else { return false }
                return label.contains("Mobile")
            }

            // If none was found, just use the first phone number.
            if phone == nil { phone = contact.phoneNumbers.first }

            // Get the phone number from this object.
            if let phone { cellNumber = phone.value.stringValue }

            focus = \Self.firstName

            // TODO: Why are taps on the Add button ignored after this
            // TODO: unless you tap it many times or
            // TODO: move focus to another TextField before tapping it?
        }
        .sheet(isPresented: $isFindingContact) {
            ContactPicker(contact: $contact)
        }
    }
}
