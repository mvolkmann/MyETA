import CoreData

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Model")

    init() {
        container.loadPersistentStores { _, error in
            if let error {
                Log.error(
                    "CoreData failed to load: \(error.localizedDescription)"
                )
            }
        }
    }
}
