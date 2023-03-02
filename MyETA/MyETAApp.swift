import MessageUI
import SwiftUI

@main
struct MyETAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ViewModel())
        }
    }
}
