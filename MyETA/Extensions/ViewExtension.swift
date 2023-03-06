import SwiftUI

extension View {
    #if os(iOS)
        @available(iOSApplicationExtension, unavailable)
        func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    #endif

    func numbersOnly(
        _ text: Binding<String>,
        float: Bool = false
    ) -> some View {
        modifier(NumbersOnlyViewModifier(text: text, float: float))
    }
}
