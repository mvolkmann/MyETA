import SwiftUI

struct SendScreen: View {
    private var isFocused: FocusState<Bool>.Binding

    init(isFocused: FocusState<Bool>.Binding) {
        self.isFocused = isFocused
    }

    var body: some View {
        Text("Send").font(.largeTitle)
    }
}
