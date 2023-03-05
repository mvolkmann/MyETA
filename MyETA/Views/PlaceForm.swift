import MapKit
import SwiftUI

struct PlaceForm: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FocusState private var focus: AnyKeyPath?

    @State private var city = ""
    @State private var country = ""
    @State private var index: Int?
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

    private func save() {
        do {
            try moc.save()
        } catch {
            errorVM.notify(
                error: error,
                message: "Failed to save place to Core Data."
            )
        }
    }

    private var validAddress: Bool {
        !street.isEmpty && postalCode.count >= 5
    }

    private var validPlace: Bool {
        !name.isEmpty &&
            !street.isEmpty &&
            !city.isEmpty &&
            !state.isEmpty &&
            postalCode.count >= 5
    }

    var body: some View {
        ZStack {
            let fill = gradient(.orange, colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

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

                if validAddress && region.center.latitude != 0 {
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(width: 200, height: 200)
                }

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
                            place.country = country.isEmpty ? "USA" : country
                            place.postalCode = postalCode
                            place.id = UUID()
                            save()
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!validPlace)

                    Button("Cancel") { dismiss() }
                        .buttonStyle(.bordered)
                }
            }
            .textFieldStyle(.roundedBorder)
            .padding()
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

                print("\(#fileID) \(#function) addressString =", addressString)
                Task {
                    placemark = try? await MapService.getPlacemark(
                        from: addressString
                    )
                    if let placemark, let location = placemark.location {
                        region.center = location.coordinate
                    }
                }
            }
        }
    }
}
