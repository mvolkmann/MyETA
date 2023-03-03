import SwiftUI

private struct PersonRow: View {
    var person: Person

    var body: some View {
        Text("\(person.firstName) \(person.lastName)")
    }
}

struct PlacesScreen: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ]
    ) var places: FetchedResults<PlaceEntity>

    @State private var errorMessage: String?
    @State private var isShowingForm = false
    @State private var place: PlaceEntity?

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
            errorMessage = nil
        } catch {
            Log.error(error)
            errorMessage = error.localizedDescription
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Places").font(.largeTitle)
                Button(action: {
                    place = nil
                    isShowingForm = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            // editActions doesn't work with CoreData models.
            // List($vm.places, editActions: .all) { $place in
            List {
                ForEach(places) { place in
                    placeRow(place)
                }
            }
            .listStyle(.grouped)
        }
        .padding()
        .sheet(isPresented: $isShowingForm) {
            PlaceForm(place: $place)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}
