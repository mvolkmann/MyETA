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

struct ContentView: View {
    private let messageComposeDelegate = MessageComposerDelegate()

    private func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else { return }

        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        if let vc = windowScene?.windows.first?.rootViewController {
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = messageComposeDelegate
            composeVC.subject = "My ETA" // used?
            composeVC.recipients = ["314-398-6256"]
            composeVC.body = "I will arrive close to 5:30 PM."
            vc.present(composeVC, animated: true)
        }
    }

    var body: some View {
        VStack {
            Button("Send") {
                presentMessageCompose()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
