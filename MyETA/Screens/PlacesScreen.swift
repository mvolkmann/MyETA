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

    @State private var isActive = false
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
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to save places change to Core Data."
            )
        }
    }

    var body: some View {
        ZStack {
            let fill = gradient(colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

            VStack {
                /*
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
                 */

                if !places.isEmpty {
                    // editActions doesn't work with CoreData models.
                    // List($vm.places, editActions: .all) { $place in
                    List {
                        ForEach(places) { place in
                            placeRow(place)
                        }
                        .onDelete(perform: deletePlace)
                    }
                    .scrollContentBackground(.hidden) // hides default background
                }

                Spacer()
            }
            .padding()
        }
        .onAppear { isActive = true }
        .onDisappear { isActive = false }
        .sheet(isPresented: $isShowingForm) {
            PlaceForm(place: $place)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
        .toolbar {
            if isActive {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        place = nil
                        isShowingForm = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("add-place-button")
                }
            }
        }
    }
}
