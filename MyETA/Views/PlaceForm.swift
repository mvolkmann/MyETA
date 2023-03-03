import SwiftUI

struct PlaceForm: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: ViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var city = ""
    @State private var country = ""
    @State private var index: Int?
    @State private var name = ""
    @State private var postalCode = ""
    @State private var state = ""
    @State private var street = ""

    @Binding var place: Place
    @Binding var isAdding: Bool

    private let textFieldWidth: CGFloat = 250

    private var canAdd: Bool {
        !name.isEmpty && !city.isEmpty && !state.isEmpty && postalCode
            .count >= 5
    }

    private func labeledTextField(
        label: String,
        text: Binding<String>,
        focusedPath: KeyPath<PlaceForm, String>
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
        case \Self.name: focus = \Self.street
        case \Self.street: focus = \Self.city
        case \Self.city: focus = \Self.state
        case \Self.state: focus = \Self.country
        case \Self.country: focus = \Self.postalCode
        case \Self.postalCode: focus = \Self.name
        default: break
        }
    }

    var body: some View {
        VStack {
            labeledTextField(
                label: "Name",
                text: $name,
                focusedPath: \Self.name
            )
            labeledTextField(
                label: "Street",
                text: $street,
                focusedPath: \Self.street
            )
            labeledTextField(
                label: "City",
                text: $city,
                focusedPath: \Self.city
            )
            labeledTextField(
                label: "State",
                text: $state,
                focusedPath: \Self.state
            )
            labeledTextField(
                label: "Country",
                text: $country,
                focusedPath: \Self.country
            )
            labeledTextField(
                label: "Postal Code",
                text: $postalCode,
                focusedPath: \Self.postalCode
            )

            HStack {
                let word = isAdding ? "Add" : "Update"
                Button("\(word) Place") {
                    let place = Place(
                        name: name,
                        street: street,
                        city: city,
                        state: state,
                        country: country.isEmpty ? "USA" : country,
                        postalCode: postalCode
                    )
                    if isAdding {
                        vm.places.append(place)
                    } else if let index {
                        vm.places[index] = place
                    }
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
            name = place.name
            street = place.street
            city = place.city
            state = place.state
            country = place.country
            postalCode = place.postalCode

            index = vm.places.firstIndex { p in p.id == place.id }

            focus = \Self.name // initial focus
        }
    }
}
