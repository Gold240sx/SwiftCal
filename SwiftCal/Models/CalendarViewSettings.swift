import Foundation
import SwiftData

@Model
final class CalendarViewSettings {
    var showOnlyMonthDays: Bool
    var showMonthCarots: Bool
    
    init(showOnlyMonthDays: Bool = false, showMonthCarots: Bool = true) {
        self.showOnlyMonthDays = showOnlyMonthDays
        self.showMonthCarots = showMonthCarots
    }
} 