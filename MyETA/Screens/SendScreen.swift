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
        entity: PersonEntity.entity(), // TODO: needed?
        sortDescriptors: [
            NSSortDescriptor(key: "lastName", ascending: true),
            NSSortDescriptor(key: "firstName", ascending: true)
        ]
    ) var people: FetchedResults<PersonEntity>

    @FetchRequest(
        entity: PlaceEntity.entity(), // TODO: needed?
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ]
    ) var places: FetchedResults<PlaceEntity>

    @State private var errorMessage: String?
    @State private var person: PersonEntity!
    @State private var place: PlaceEntity!
    @State private var processing = false

    private let messageComposeDelegate = MessageComposerDelegate()

    private func getMessage() async throws -> String {
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

        guard let cellNumber = person.cellNumber else {
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

    var body: some View {
        VStack {
            Picker("Person", selection: $person) {
                ForEach(people) { person in
                    let firstName = person.firstName ?? ""
                    let lastName = person.lastName ?? ""
                    Text("\(firstName) \(lastName)")
                }
            }

            Picker("Place", selection: $place) {
                ForEach(places) { place in
                    let name = place.name ?? ""
                    let street = place.street ?? ""
                    Text("\(name) \(street)")
                }
            }

            if processing {
                ProgressView()
            } else {
                Button("Send ETA", action: presentMessageCompose)
                    .buttonStyle(.borderedProminent)
                    .disabled(person == nil || place == nil)
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
            person = people.first
            place = places.first
        }
    }
}
