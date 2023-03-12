import SwiftUI

private struct PersonRow: View {
    var person: Person

    var body: some View {
        Text("\(person.firstName) \(person.lastName)")
    }
}

struct PlacesScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ]
    ) var places: FetchedResults<PlaceEntity>

    @State private var isShowingForm = false
    @State private var place: PlaceEntity?

    private var buttons: some View {
        HStack {
            AddContact()

            Button("Add Manually") {
                place = nil
                isShowingForm = true
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("add-place-button")
        }
    }

    private func deletePlace(at indexSet: IndexSet) {
        for index in indexSet {
            moc.delete(places[index])
        }
        save()
    }

    private func placeRow(_ place: PlaceEntity) -> some View {
        Text(place.name ?? "")
            .onTapGesture {
                self.place = place
                isShowingForm = true
            }
    }

    private func save() {
        do {
            try moc.save()
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to save places change in Core Data."
            )
        }
    }

    var body: some View {
        ZStack {
            let fill = gradient(colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

            VStack {
                buttons

                if !places.isEmpty {
                    // editActions doesn't work with CoreData models.
                    // List($vm.places, editActions: .all) { $place in
                    List {
                        ForEach(places) { place in
                            placeRow(place)
                        }
                        .onDelete(perform: deletePlace)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden) // hides default background
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingForm) {
            PlaceForm(place: $place)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}
