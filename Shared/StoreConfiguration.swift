import Foundation

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