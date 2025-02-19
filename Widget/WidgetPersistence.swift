import CoreData

struct WidgetPersistence {
    static let shared = WidgetPersistence()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "SwiftCal")
        
        // Configure the container to use the shared store URL
        let storeURL = StoreConfiguration.containerURL
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Widget Store Error: \(error.localizedDescription)")
            }
        }
    }
    
    func getCurrentStreak() -> Int {
        // Use the Calculations struct instead of StreakView
        return Calculations.getStreakValue(context: container.viewContext)
    }
} 