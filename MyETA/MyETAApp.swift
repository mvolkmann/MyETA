import MessageUI
import SwiftUI

@main
struct MyETAApp: App {
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext,
                    dataController.container.viewContext
                )
                .environmentObject(ErrorViewModel())
        }
    }
}
