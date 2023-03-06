import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var errorVM: ErrorViewModel

    @State private var appInfo: AppInfo?
    @State private var isInfoPresented = false
    @State private var selection = "Send"

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                SendScreen()
                    .tabItem {
                        Label("Send ETA", systemImage: "gear")
                            .accessibilityIdentifier("send-eta-tab")
                    }
                    .tag("Send")
                PeopleScreen()
                    .tabItem {
                        Label("People", systemImage: "person.3")
                            .accessibilityIdentifier("people-tab")
                    }
                    .tag("People")
                PlacesScreen()
                    .tabItem {
                        Label("Places", systemImage: "building.2")
                            .accessibilityIdentifier("places-tab")
                    }
                    .tag("Places")
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
        }

        .alert(
            "Error",
            isPresented: $errorVM.errorOccurred,
            actions: {}, // no custom buttons
            message: { errorVM.text }
        )

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
