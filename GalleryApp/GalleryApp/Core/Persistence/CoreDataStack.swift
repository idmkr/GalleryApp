import CoreData

final class CoreDataStack {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    /// inMemory = true нужен для unit-тестов: данные не пишутся на диск.
    init(modelName: String = "Gallery", inMemory: Bool = false) {
        container = NSPersistentContainer(name: modelName)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load persistent store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
