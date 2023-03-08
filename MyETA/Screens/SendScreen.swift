import CoreLocation
import MapKit
import MessageUI
import SwiftUI

private class MessageComposerDelegate: NSObject,
    MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true)
    }
}

struct SendScreen: View {
    private static let mapMeters: CLLocationDistance = 1000

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
    ) var people: FetchedResults<PersonEntity>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ]
    ) var places: FetchedResults<PlaceEntity>

    @State private var eta: Date?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(),
        latitudinalMeters: Self.mapMeters,
        longitudinalMeters: Self.mapMeters
    )
    @State private var processing = false
    @State private var selectedPersonId: UUID?
    @State private var selectedPlaceId: UUID?

    @StateObject var locationVM = LocationViewModel()

    private let messageComposeDelegate = MessageComposerDelegate()

    private var buttonsView: some View {
        HStack {
            if processing {
                ProgressView().scaleEffect(1.5)
            } else {
                if let eta {
                    Text("ETA: \(eta.time)")
                } else {
                    Button("Show ETA", action: presentETA)
                        .buttonStyle(.bordered)
                        .disabled(selectedPlace == nil)
                }
                Button("Send ETA", action: presentMessageCompose)
                    .buttonStyle(.bordered)
                    .disabled(
                        selectedPerson == nil || selectedPlace == nil
                    )
            }
        }
        .frame(height: 40)
    }

    private func getETA() async throws {
        guard let place = selectedPlace else {
            throw "A place must be selected."
        }
        guard let placemark =
            try await MapService.getPlacemark(from: place) else {
            throw "No placemark found for place."
        }

        guard let from = locationVM.location else {
            errorVM.alert(
                message: "Failed to get curent location."
            )
            return
        }

        let seconds = try await MapService.travelTime(
            from: from,
            to: placemark
        )
        eta = Date.now.addingTimeInterval(seconds)
    }

    private func getMessage() async throws -> String {
        guard let person = selectedPerson else {
            throw "A person must be selected."
        }
        let firstName = person.firstName ?? "unknown"
        try await getETA()
        let time = eta?.time ?? "unknown"
        let name = selectedPlace?.name ?? ""
        return "\(firstName), I will arrive at \(name) around \(time)."
    }

    private var locationView: some View {
        VStack {
            HStack {
                Text("Your Location").font(.headline)
                Button(action: refreshLocation) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                }
            }
            Map(coordinateRegion: $region, showsUserLocation: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(10)
        }
    }

    @ViewBuilder
    private var peopleView: some View {
        if people.isEmpty {
            missingData("People")
        } else {
            // TODO: Why doesn't it work to make selection and the tag values
            // TODO: have the type PersonEntity instead of UUID?
            Picker("Person", selection: $selectedPersonId) {
                ForEach(people, id: \.id) { (person: PersonEntity) in
                    let firstName = person.firstName ?? ""
                    let lastName = person.lastName ?? ""
                    Text("\(firstName) \(lastName)").tag(person)
                }
            }
            .background(.white)
            .cornerRadius(10)
        }
    }

    @ViewBuilder
    private var placesView: some View {
        if places.isEmpty {
            missingData("Places")
        } else {
            // TODO: Why doesn't it work to make selection and the tag values
            // TODO: have the type PlaceEntity instead of UUID?
            Picker("Place", selection: $selectedPlaceId) {
                ForEach(places) { place in
                    Text(place.name ?? "").tag(place)
                }
            }
            .background(.white)
            .cornerRadius(10)
        }
    }

    private func presentETA() {
        Task {
            do {
                processing = true
                try await getETA()
                processing = false
            } catch {
                errorVM.alert(
                    error: error,
                    message: "Failed to get ETA."
                )
            }
        }
    }

    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else {
            errorVM.alert(
                message: "Permission to send text messages has not been granted."
            )
            return
        }

        guard let mobileNumber = selectedPerson?.mobileNumber else {
            errorVM.alert(
                message: "The selected person has no mobile number."
            )
            return
        }

        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        if let vc = windowScene?.windows.first?.rootViewController {
            var message = ""
            Task {
                do {
                    processing = true
                    message = try await getMessage()

                    let composeVC = MFMessageComposeViewController()
                    composeVC.messageComposeDelegate = messageComposeDelegate
                    composeVC.recipients = [mobileNumber]
                    composeVC.body = message
                    vc.present(composeVC, animated: true)
                    processing = false
                } catch {
                    errorVM.alert(
                        error: error,
                        message: "Failed to compose text message."
                    )
                    processing = false
                }
            }
        } else {
            errorVM.alert(
                message: "Failed to get root ViewController."
            )
        }
    }

    private var selectedPerson: PersonEntity? {
        people.first { p in p.id == selectedPersonId }
    }

    private var selectedPlace: PlaceEntity? {
        places.first { p in p.id == selectedPlaceId }
    }

    private func missingData(_ tab: String) -> some View {
        Text("Tap the \(tab) tab to add some.")
            .font(.headline)
            .padding(.bottom)
    }

    private func refreshLocation() {
        locationVM.requestLocation()
    }

    var body: some View {
        ZStack {
            let fill = gradient(colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

            VStack {
                Spacer()
                peopleView
                placesView
                if !people.isEmpty, !places.isEmpty {
                    buttonsView
                }
                locationView
                Spacer()
            }
            .padding()
            .pickerStyle(.inline)
            .onAppear {
                selectedPersonId = people.first?.id
                selectedPlaceId = places.first?.id
                refreshLocation()
            }
            .onChange(of: selectedPlace) { _ in
                eta = nil
            }
            .onChange(of: locationVM.location) { location in
                if let location { region.center = location }
            }
        }
    }
}
