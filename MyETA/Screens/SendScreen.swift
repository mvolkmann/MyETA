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
    @State private var processing = false
    @State private var selectedPerson: PersonEntity?
    @State private var selectedPlace: PlaceEntity?

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
        print(
            "\(#fileID) \(#function) selectedPerson =",
            selectedPerson ?? "none"
        )
        print(
            "\(#fileID) \(#function) selectedPlace =",
            selectedPlace ?? "none"
        )
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

    var body: some View {
        VStack {
            Picker("Person", selection: $selectedPerson) {
                ForEach(people) { person in
                    let firstName = person.firstName ?? ""
                    let lastName = person.lastName ?? ""
                    Text("\(firstName) \(lastName)").tag(person)
                }
            }
            .onChange(of: selectedPerson) { p in
                print("\(#fileID) \(#function) p =", p)
            }

            Picker("Place", selection: $selectedPlace) {
                ForEach(places) { place in
                    Text(place.name ?? "").tag(place)
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
            print("\(#fileID) \(#function) entered")
            selectedPerson = people.first
            selectedPlace = places.first
        }
    }
}
