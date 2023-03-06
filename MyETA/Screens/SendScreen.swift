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

    private let messageComposeDelegate = MessageComposerDelegate()

    @ViewBuilder
    private var buttonsView: some View {
        if processing {
            ProgressView().scaleEffect(1.5)
        } else {
            HStack {
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
    }

    private func getETA() async throws {
        guard let place = selectedPlace else {
            throw "A place must be selected."
        }
        guard let placemark =
            try await MapService.getPlacemark(from: place) else {
            throw "No placemark found for place."
        }

        let seconds = try await MapService.travelTime(to: placemark)
        eta = Date.now.addingTimeInterval(seconds)
    }

    private func getMessage() async throws -> String {
        guard let person = selectedPerson else {
            throw "A person must be selected."
        }
        /*
         guard let place = selectedPlace else { return "" }

         guard let placemark = try await MapService.getPlacemark(from: place)
         else {
             throw "No placemark found for place."
         }

         let seconds = try await MapService.travelTime(to: placemark)
         let eta = Date.now.addingTimeInterval(seconds)
         */
        let firstName = person.firstName ?? "unknown"
        try await getETA()
        let time = eta?.time ?? "unknown"
        let name = selectedPlace?.name ?? ""
        return "\(firstName), I will arrive at \(name) around \(time)."
    }

    private var locationView: some View {
        Group {
            HStack {
                Text("Your Location").font(.headline)
                Button(action: refreshLocation) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                }
            }
            Map(
                coordinateRegion: $region,
                // TODO: Why does this seem to have no effect?
                showsUserLocation: true
            )
            .frame(width: 200, height: 200)
        }
    }

    @ViewBuilder
    private var peopleView: some View {
        if people.isEmpty {
            missingData("People")
        } else {
            // TODO: Why doesn't it work to make selection and the tag values be PersonEntity instead of UUID?
            Picker("Person", selection: $selectedPersonId) {
                ForEach(people, id: \.id) { (person: PersonEntity) in
                    let firstName = person.firstName ?? ""
                    let lastName = person.lastName ?? ""
                    Text("\(firstName) \(lastName)").tag(person)
                }
            }
            .border(.white)
        }
    }

    @ViewBuilder
    private var placesView: some View {
        if places.isEmpty {
            missingData("Places")
        } else {
            // TODO: Why doesn't it work to make selection and the tag values be PlaceEntity instead of UUID?
            Picker("Place", selection: $selectedPlaceId) {
                ForEach(places) { place in
                    Text(place.name ?? "").tag(place)
                }
            }
            .border(.white)
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

        guard let cellNumber = selectedPerson?.cellNumber else {
            errorVM.alert(
                message: "The selected person has no cell number."
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
                    composeVC.recipients = [cellNumber]
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
        do {
            let location = try MapService.currentLocation()
            region.center = location.coordinate
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to get current location."
            )
        }
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
            .pickerStyle(.wheel)
            .onAppear {
                selectedPersonId = people.first?.id
                selectedPlaceId = places.first?.id
                refreshLocation()
            }
            .onChange(of: selectedPlace) { _ in
                eta = nil
            }
        }
    }
}
