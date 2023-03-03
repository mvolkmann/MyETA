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
    @EnvironmentObject private var vm: ViewModel

    @State private var errorMessage: String?
    @State private var person: Person!
    @State private var place: Place!
    @State private var processing = false

    private let messageComposeDelegate = MessageComposerDelegate()

    private func getMessage() async throws -> String {
        let addressString =
            "\(place.street), \(place.city), \(place.state), \(place.postalCode)"
        let placemark = try await MapService.getPlacemark(
            from: addressString
        )
        let seconds = try await MapService.travelTime(to: placemark)
        let eta = Date.now.addingTimeInterval(seconds)
        return "\(person.firstName), I will arrive at \(place.name) around \(eta.time)."
    }

    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else {
            errorMessage =
                "Permission to sent text messages has not been granted."
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
                    composeVC.recipients = [person.cellNumber]
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
                ForEach(vm.people) { person in
                    Text("\(person.firstName) \(person.lastName)")
                }
            }

            Picker("Place", selection: $place) {
                ForEach(vm.places) { place in
                    Text("\(place.name) \(place.street)")
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
            person = vm.people.first
            place = vm.places.first
        }
    }
}
