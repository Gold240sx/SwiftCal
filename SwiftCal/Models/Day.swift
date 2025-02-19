import Foundation
import SwiftData

@Model
final class Day {
    var date: Date
    var didStudy: Bool
    
    init(date: Date = Date(), didStudy: Bool = false) {
        self.date = date
        self.didStudy = didStudy
    }
} 