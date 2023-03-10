import Contacts
import MapKit
import SwiftUI

struct PlaceForm: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var city = ""
    @State private var contact: CNContact?
    @State private var country = ""
    @State private var index: Int?
    @State private var isFindingContact = false
    @State private var name = ""
    @State private var placemark: CLPlacemark?
    @State private var postalCode = ""
    @State private var state = ""
    @State private var street = ""

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        latitudinalMeters: 1000,
        longitudinalMeters: 1000
    )

    @Binding var place: PlaceEntity?

    private let textFieldWidth: CGFloat = 250

    private var addressString: String {
        "\(street), \(city), \(state), \(postalCode)"
    }

    private var buttonsView: some View {
        HStack {
            let adding = place == nil
            let word = adding ? "Add" : "Update"
            Button("\(word) Place") {
                if adding {
                    place = PlaceEntity(context: moc)
                }
                if let place {
                    place.name = name
                    place.street = street
                    place.city = city
                    place.state = state
                    place.country = country
                        .isEmpty ? "USA" : country
                    place.postalCode = postalCode
                    place.id = UUID()
                    save()
                }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!validPlace)
            .accessibilityIdentifier("add-button")

            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("cancel-button")
        }
    }

    private func changeContact(_ contact: CNContact?) {
        guard let contact else { return }

        guard let postalAddress = contact.postalAddresses.first
        else { return }

        if contact.givenName.isEmpty {
            name = contact.organizationName
        } else {
            name = "\(contact.givenName) \(contact.familyName)"
        }

        let address = postalAddress.value
        street = address.street
        city = address.city
        state = address.state
        country = address.country
        postalCode = address.postalCode
    }

    private var fieldsView: some View {
        Group {
            labeledTextField(
                label: "Name *",
                text: $name,
                focusedPath: \Self.name,
                identifier: "name-text-field"
            )
            labeledTextField(
                label: "Street *",
                text: $street,
                focusedPath: \Self.street,
                identifier: "street-text-field"
            )
            labeledTextField(
                label: "City",
                text: $city,
                focusedPath: \Self.city,
                identifier: "city-text-field"
            )
            labeledTextField(
                label: "State",
                text: $state,
                focusedPath: \Self.state,
                identifier: "state-text-field"
            )
            labeledTextField(
                label: "Country",
                text: $country,
                focusedPath: \Self.country,
                identifier: "country-text-field"
            )
            labeledTextField(
                label: "Postal Code *",
                text: $postalCode,
                focusedPath: \Self.postalCode,
                identifier: "postal-code-text-field"
            )
        }
        .textFieldStyle(.roundedBorder)
    }

    private func labeledTextField(
        label: String,
        text: Binding<String>,
        focusedPath: KeyPath<PlaceForm, String>,
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

    private var mapView: some View {
        Map(
            coordinateRegion: $region,
            annotationItems: [
                IdentifiableLocation(region.center)
            ]
        ) { place in
            MapMarker(coordinate: place.location, tint: .red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(10)
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

    private func save() {
        do {
            try moc.save()
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to save place to Core Data."
            )
        }
    }

    private var validAddress: Bool {
        !street.isEmpty && postalCode.count >= 5
    }

    private var validPlace: Bool {
        !name.isEmpty && !street.isEmpty && postalCode.count >= 5
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
                    .buttonStyle(.bordered)

                    buttonsView

                    if validAddress && region.center.latitude != 0 {
                        mapView
                    }

                    Spacer()
                }
                .padding()
                .padding(.top)
                .onAppear {
                    name = place?.name ?? ""
                    street = place?.street ?? ""
                    city = place?.city ?? ""
                    state = place?.state ?? ""
                    country = place?.country ?? ""
                    postalCode = place?.postalCode ?? ""
                    focus = \Self.name // initial focus
                }
                .onChange(of: addressString) { _ in
                    guard validAddress else { return }
                    Task {
                        placemark = try? await MapService.getPlacemark(
                            from: addressString
                        )
                        if let placemark, let location = placemark.location {
                            region.center = location.coordinate
                        }
                    }
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
        .onChange(of: contact, perform: changeContact)
        .sheet(isPresented: $isFindingContact) {
            ContactPicker(contact: $contact)
        }
    }
}
