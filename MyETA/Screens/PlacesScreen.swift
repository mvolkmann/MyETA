import SwiftUI

private struct PersonRow: View {
    var person: Person

    var body: some View {
        Text("\(person.firstName) \(person.lastName)")
    }
}

struct PlacesScreen: View {
    @EnvironmentObject private var vm: ViewModel

    @State private var isShowingForm = false
    @State private var place = Place(
        name: "",
        street: "",
        city: "",
        state: "",
        country: "",
        postalCode: ""
    )

    private func placeRow(_ place: Place) -> some View {
        Text("\(place.name), \(place.street), \(place.city)")
            .onTapGesture {
                self.place = place
                isShowingForm = true
            }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Places").font(.largeTitle)
                Button(action: {
                    place = Place(
                        name: "",
                        street: "",
                        city: "",
                        state: "",
                        country: "",
                        postalCode: ""
                    )
                    isShowingForm = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                }
            }

            List($vm.places, editActions: .all) { $place in
                placeRow(place)
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
