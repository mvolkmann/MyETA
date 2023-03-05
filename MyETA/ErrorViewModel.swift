import SwiftUI

struct ErrorWrapper: Identifiable {
    let error: Error?
    let message: String
    let id = UUID()
}

class ErrorViewModel: ObservableObject {
    @Published var haveError = false
    @Published var wrapper: ErrorWrapper?

    func notify(error: Error? = nil, message: String) {
        if let error { Log.error(error) }
        wrapper = ErrorWrapper(error: error, message: message)
        haveError = true
    }

    var text: Text {
        guard let wrapper else {
            return Text("No error occurred.")
        }

        if let error = wrapper.error {
            let desc = error.localizedDescription
            return Text(wrapper.message + "\n" + desc)
        } else {
            return Text(wrapper.message)
        }
    }
}
