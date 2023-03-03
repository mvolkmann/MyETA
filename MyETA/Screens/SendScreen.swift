import CoreLocation
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
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var person: Person!
    @State private var place: Place!

    private let messageComposeDelegate = MessageComposerDelegate()

    private func getMessage() async -> String {
        let latitude = 38.5864931
        let longitude = -90.2842
        let location = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        do {
            let seconds = try await mapKitVM.travelTime(to: location)
            let eta = Date.now.addingTimeInterval(seconds)
            return "\(person.firstName), I will arrive at \(place.name) around \(eta.time)."
        } catch {
            return error.localizedDescription
        }
    }

    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else { return }

        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        if let vc = windowScene?.windows.first?.rootViewController {
            var message = ""
            Task {
                message = await getMessage()
                print("\(#fileID) \(#function) message =", message)
                let composeVC = MFMessageComposeViewController()
                composeVC.messageComposeDelegate = messageComposeDelegate
                composeVC.subject = "My ETA" // used?
                composeVC.recipients = [person.cellNumber]
                composeVC.body = message
                vc.present(composeVC, animated: true)
            }
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
