import Contacts
import ContactsUI
import SwiftUI

struct ContactPicker<Label: View>: UIViewControllerRepresentable {
    class Coordinator: NSObject, CNContactPickerDelegate {
        var onCancel: () -> Void
        var viewController: UIViewController = .init()
        var picker = CNContactPickerViewController()

        @Binding var contact: CNContact?

        // Possible take a binding
        init<Label: View>(
            contact: Binding<CNContact?>,
            onCancel: @escaping () -> Void,
            @ViewBuilder content: @escaping () -> Label
        ) {
            _contact = contact
            self.onCancel = onCancel
            super.init()
            let button = Button<Label>(
                action: showContactPicker,
                label: content
            )

            let hostingController: UIHostingController<Button<Label>> =
                UIHostingController(rootView: button)

            hostingController.view?.sizeToFit()

            (hostingController.view?.frame).map {
                hostingController.view!.widthAnchor
                    .constraint(equalToConstant: $0.width).isActive = true
                hostingController.view!.heightAnchor
                    .constraint(equalToConstant: $0.height).isActive = true
                viewController.preferredContentSize = $0.size
            }

            hostingController.willMove(toParent: viewController)
            viewController.addChild(hostingController)
            viewController.view.addSubview(hostingController.view)

            hostingController.view.anchor(to: viewController.view)

            picker.delegate = self
        }

        func showContactPicker() {
            viewController.present(picker, animated: true)
        }

        func contactPickerDidCancel(_: CNContactPickerViewController) {
            onCancel()
        }

        func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contact: CNContact
        ) {
            self.contact = contact
        }

        func makeUIViewController() -> UIViewController {
            return viewController
        }

        func updateUIViewController(
            _ uiViewController: UIViewController,
            context: UIViewControllerRepresentableContext<ContactPicker>
        ) {}
    }

    @Binding var contact: CNContact?

    @ViewBuilder
    var content: () -> Label

    var onCancel: () -> Void

    init(
        contact: Binding<CNContact?>,
        onCancel: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Label
    ) {
        _contact = contact
        self.onCancel = onCancel
        self.content = content
    }

    func makeCoordinator() -> Coordinator {
        .init(contact: $contact, onCancel: onCancel, content: content)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.makeUIViewController()
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
        context.coordinator.updateUIViewController(
            uiViewController,
            context: context
        )
    }
}

private extension UIView {
    func anchor(to other: UIView) {
        translatesAutoresizingMaskIntoConstraints = false

        topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
    }
}
