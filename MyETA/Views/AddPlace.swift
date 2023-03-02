import SwiftUI

struct AddPlace: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: ViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var name = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var country = ""
    @State private var postalCode = ""

    let textFieldWidth: CGFloat = 250

    private var canAdd: Bool {
        !name.isEmpty && !city.isEmpty && !state.isEmpty && postalCode
            .count >= 5
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
            LabeledContent("Name") {
                TextField("name", text: $name, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.name)
            }
            LabeledContent("Street") {
                TextField("street", text: $street, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.street)
            }
            LabeledContent("City") {
                TextField("city", text: $city, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.city)
            }
            LabeledContent("State") {
                TextField("state", text: $state, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.state)
            }
            LabeledContent("Country") {
                TextField("country", text: $country, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.country)
            }
            LabeledContent("Postal Code") {
                TextField("postal code", text: $postalCode, onCommit: nextFocus)
                    .frame(width: textFieldWidth)
                    .focused($focus, equals: \Self.postalCode)
            }

            HStack {
                Button("Add Place") {
                    vm.addPlace(Place(
                        name: name,
                        street: street,
                        city: city,
                        state: state,
                        country: country.isEmpty ? "USA" : country,
                        postalCode: postalCode
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
            focus = \Self.name // initial focus
        }
    }
}
