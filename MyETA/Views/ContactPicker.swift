import ContactsUI
import SwiftUI

struct ContactPicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, CNContactPickerDelegate {
        private var parent: ContactPicker

        init(_ parent: ContactPicker) {
            self.parent = parent
        }

        func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contact: CNContact
        ) {
            // picker.dismiss(animated: true) // seems not needed
            parent.contact = contact
        }
    }

    @Binding private var contact: CNContact?

    init(contact: Binding<CNContact?>) {
        _contact = contact
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context)
        -> CNContactPickerViewController {
        let vc = CNContactPickerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    // This method is required, but in this case it doesn't need to anything.
    func updateUIViewController(
        _ uiViewController: CNContactPickerViewController,
        context: Context
    ) {}
}
