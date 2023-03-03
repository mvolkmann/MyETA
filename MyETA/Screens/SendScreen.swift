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
    @Environment(\.managedObjectContext) var moc

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

    @State private var errorMessage: String?
    @State private var processing = false
    @State private var selectedPersonId: UUID?
    @State private var selectedPlaceId: UUID?

    private let messageComposeDelegate = MessageComposerDelegate()

    private func getMessage() async throws -> String {
        guard let person = selectedPerson else { return "" }
        guard let place = selectedPlace else { return "" }

        let street = place.street ?? ""
        let city = place.city ?? ""
        let state = place.state ?? ""
        let postalCode = place.postalCode ?? ""
        let addressString = "\(street), \(city), \(state), \(postalCode)"
        let placemark = try await MapService.getPlacemark(
            from: addressString
        )

        let seconds = try await MapService.travelTime(to: placemark)
        let eta = Date.now.addingTimeInterval(seconds)

        let firstName = person.firstName ?? ""
        let name = place.name ?? ""
        return "\(firstName), I will arrive at \(name) around \(eta.time)."
    }

    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else {
            errorMessage =
                "Permission to sent text messages has not been granted."
            return
        }

        guard let cellNumber = selectedPerson?.cellNumber else {
            errorMessage = "The selected person has no cell number."
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
                    errorMessage = nil

                    let composeVC = MFMessageComposeViewController()
                    composeVC.messageComposeDelegate = messageComposeDelegate
                    composeVC.recipients = [cellNumber]
                    composeVC.body = message
                    vc.present(composeVC, animated: true)
                    processing = false
                } catch {
                    errorMessage = error.localizedDescription
                    processing = false
                }
            }
        } else {
            errorMessage = "Failed to get root ViewController."
        }
    }

    private var selectedPerson: PersonEntity? {
        people.first { p in p.id == selectedPersonId }
    }

    private var selectedPlace: PlaceEntity? {
        places.first { p in p.id == selectedPlaceId }
    }

    var body: some View {
        VStack {
            if people.isEmpty {
                Text("Tap the People tab to add some.")
            } else {
                // TODO: Why doesn't it work to make selection and the tag values be PersonEntity instead of UUID?
                Picker("Person", selection: $selectedPersonId) {
                    ForEach(people, id: \.id) { (person: PersonEntity) in
                        let firstName = person.firstName ?? ""
                        let lastName = person.lastName ?? ""
                        Text("\(firstName) \(lastName)").tag(person)
                    }
                }
            }

            if places.isEmpty {
                Text("Tap the Places tab to add some.")
            } else {
                // TODO: Why doesn't it work to make selection and the tag values be PlaceEntity instead of UUID?
                Picker("Place", selection: $selectedPlaceId) {
                    ForEach(places) { place in
                        Text(place.name ?? "").tag(place)
                    }
                }
            }

            if processing {
                ProgressView()
            } else {
                Button("Send ETA", action: presentMessageCompose)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPerson == nil || selectedPlace == nil)
            }

            if let errorMessage {
                Text(errorMessage)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .pickerStyle(.wheel)
        .onAppear {
            selectedPersonId = people.first?.id
            selectedPlaceId = places.first?.id
        }
    }
}
