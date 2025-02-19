//
//  Persistence.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import CoreData
import Foundation
import CloudKit

// Temporary: Move StoreConfiguration here until we resolve the import issue
enum StoreConfiguration {
    static let groupIdentifier = "group.com.michaelMartell.SwiftCal"
    static let databaseName = "SwiftCal.sqlite"
    
    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            fatalError("Failed to get container URL for group: \(groupIdentifier)")
        }
        return url.appendingPathComponent(databaseName)
    }
}

struct PersistenceController {
    static let shared = PersistenceController()
    
    var oldStoreURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(StoreConfiguration.databaseName)
    }
    
    var sharedStoreURL: URL {
        StoreConfiguration.containerURL
    }

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create preview settings
        let settings = CalendarViewSettings(context: viewContext)
        settings.showOnlyMonthDays = false
        
        let startDate = Calendar.current.dateInterval(of: .month, for: .now)!.start
        
        for dayOffset in 0..<30 {
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) ?? Date()
            newDay.didStudy = Bool.random()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SwiftCal")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeURL = FileManager.default.fileExists(atPath: oldStoreURL.path) 
                ? oldStoreURL  // Use old URL if it exists
                : sharedStoreURL // Otherwise use shared URL
            
            // Configure store with simpler options
            let description = NSPersistentStoreDescription(url: storeURL)
            description.type = NSSQLiteStoreType
            
            container.persistentStoreDescriptions = [description]
            print("🌐 Using store at: \(storeURL.path)")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Failed to load persistent stores: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Successfully loaded persistent store")
        })
        
        // Only attempt migration if we can access the shared container
        if FileManager.default.fileExists(atPath: oldStoreURL.path) {
            migrateStore(for: container)
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func migrateStore(for container: NSPersistentContainer) {
        print("➡️ Attempting store migration")
        let coordinator = container.persistentStoreCoordinator
        
        guard let oldStore = coordinator.persistentStore(for: oldStoreURL) else {
            print("⚠️ No old store found to migrate")
            return
        }
        
        do {
            print("🔄 Migrating store...")
            _ = try coordinator.migratePersistentStore(oldStore, to: sharedStoreURL, type: .sqlite)
            print("✅ Migration successful")
            
            // Only attempt deletion after successful migration
            try FileManager.default.removeItem(at: oldStoreURL)
            print("🗑️ Old store deleted")
        } catch {
            print("❌ Migration failed: \(error.localizedDescription)")
        }
    }
}
