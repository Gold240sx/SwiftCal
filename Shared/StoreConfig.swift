import Foundation

enum StoreConfig {
    static let groupIdentifier = "group.com.michaelMartell.SwiftCal"
    static let storeName = "shared.store"
    
    static var containerURL: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)?
            .appendingPathComponent(storeName) ?? URL.documentsDirectory.appendingPathComponent(storeName)
    }
} 