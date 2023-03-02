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
    @FocusState private var isFocused: Bool

    @State private var appInfo: AppInfo?
    @State private var isInfoPresented = false
    @State private var selection = "Workout"

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
        /*
         VStack {
             Button("Send") {
                 presentMessageCompose()
             }
             .buttonStyle(.borderedProminent)
             Spacer()
         }
         .padding()
         */

        NavigationStack {
            TabView(selection: $selection) {
                PeopleScreen(isFocused: $isFocused)
                    .tabItem {
                        Label("People", systemImage: "person.3")
                    }
                    .tag("People")
                PlacesScreen(isFocused: $isFocused)
                    .tabItem {
                        Label(
                            "Places",
                            systemImage: "building.2"
                        )
                    }
                    .tag("Places")
                SendScreen(isFocused: $isFocused)
                    .tabItem {
                        Label(
                            "Send ETA",
                            systemImage: "gear"
                        )
                    }
                    .tag("Send")
            }

            .navigationTitle(selection)
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isInfoPresented = true }) {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityIdentifier("info-button")
                }
            }

            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button {
                        isFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }

        .sheet(isPresented: $isInfoPresented) {
            Info(appInfo: appInfo)
                // .presentationDetents([.height(410)])
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
        }

        .task {
            do {
                appInfo = try await AppInfo.create()
            } catch {
                Log.error("error getting AppInfo: \(error)")
            }
        }

        .tint(.accentColor.opacity(0.9))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
