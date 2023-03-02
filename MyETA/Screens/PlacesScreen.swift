import SwiftUI

struct PlacesScreen: View {
    private var isFocused: FocusState<Bool>.Binding

    init(isFocused: FocusState<Bool>.Binding) {
        self.isFocused = isFocused
    }

    var body: some View {
        Text("Places").font(.largeTitle)
    }
}
