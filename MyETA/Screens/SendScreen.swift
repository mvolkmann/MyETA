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
    // @StateObject var coreLocationVM = CoreLocationViewModel()

    @State private var person: Person!
    @State private var place: Place!

    private let messageComposeDelegate = MessageComposerDelegate()

    private func getMessage() -> String {
        // TODO: Use CoreLocation and MapKit to get ETA.
        return "I will arrive close to 5:30 PM."
    }

    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else { return }

        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        if let vc = windowScene?.windows.first?.rootViewController {
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = messageComposeDelegate
            composeVC.subject = "My ETA" // used?
            composeVC.recipients = [person.cellNumber]
            composeVC.body = getMessage()
            vc.present(composeVC, animated: true)
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
            Button("Send ETA", action: presentMessageCompose)
                .disabled(person == nil || place == nil)
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
