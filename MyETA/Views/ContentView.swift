import SwiftUI

struct ContentView: View {
    @State private var appInfo: AppInfo?
    @State private var isInfoPresented = false
    @State private var selection = "Send"

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                SendScreen()
                    .tabItem {
                        Label(
                            "Send ETA",
                            systemImage: "gear"
                        )
                    }
                    .tag("Send")
                PeopleScreen()
                    .tabItem {
                        Label("People", systemImage: "person.3")
                    }
                    .tag("People")
                PlacesScreen()
                    .tabItem {
                        Label(
                            "Places",
                            systemImage: "building.2"
                        )
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
