//
//  Date+Ext.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import Foundation

extension Date {

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)!.start
    }

    var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)!.end
    }

    var endOfDay: Date {
        Calendar.current.dateInterval(of: .day, for: self)!.end
    }

    var startOfPreviousMonth: Date {
        let dayInPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: self)!
        return dayInPreviousMonth.startOfMonth
    }

    var startOfNextMonth: Date {
        let dayInNextMonth = Calendar.current.date(byAdding: .month, value: 1, to: self)!
        return dayInNextMonth.startOfMonth
    }

    var numberOfDaysInMonth: Int {
        // endOfMonth returns the 1st of next month at midnight.
        // An adjustment of -1 is necessary to get last day of current month
        let endDateAdjustment = Calendar.current.date(byAdding: .day, value: -1, to: self.endOfMonth)!
        return Calendar.current.component(.day, from: endDateAdjustment)
    }

    var dayInt: Int {
        Calendar.current.component(.day, from: self)
    }

    var monthInt: Int {
        Calendar.current.component(.month, from: self)
    }

    var monthFullName: String {
        self.formatted(.dateTime.month(.wide))
    }
    
    var startOfCalendarWithPrefixDays: Date {
        // What day of the week is the first of the month?
        let startOfMonthWeekday: Int = Calendar.current.component(.weekday, from: self.startOfMonth)
        let numberOfPrefixDays = startOfMonthWeekday - 1
        let startDate = Calendar.current.date(byAdding: .day, value: -numberOfPrefixDays, to: startOfMonth)!
        return startDate
    }

    var endOfCalendarWithSuffixDays: Date {
        // What day of the week is the last day of the month?
        let endOfMonthWeekday = Calendar.current.component(.weekday, from: self.endOfMonth)
        // If it's already Saturday (7), we need 0 suffix days
        // Otherwise we need enough days to get to Saturday
        let numberOfSuffixDays = endOfMonthWeekday == 7 ? 0 : 7 - endOfMonthWeekday
        let endDate = Calendar.current.date(byAdding: .day, value: numberOfSuffixDays, to: self.endOfMonth)!
        return endDate
    }
}
