//
//  Calculations.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/19/25.
//

import Foundation
import SwiftData

struct Calculations {
    static func getStreakValue(context: ModelContext) -> Int {
        let endDate = Date().endOfDay
        
        let descriptor = FetchDescriptor<Day>(
            predicate: #Predicate<Day> { day in
                day.date <= endDate
            },
            sortBy: [SortDescriptor(\Day.date, order: .reverse)]
        )
        
        guard let days = try? context.fetch(descriptor) else { return 0 }
        return calculateStreakValue(days: days)
    }
    
    static func calculateStreakValue(days: [Day]) -> Int {
        guard !days.isEmpty else {
            print("⚠️ No days provided for streak calculation")
            return 0 
        }
        
        var streakCount = 0
        let calendar = Calendar.current
        let today = Date().startOfDay
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // First check if both today and yesterday were not studied
        let todayStudied = days.first { calendar.isDateInToday($0.date) }?.didStudy ?? false
        let yesterdayStudied = days.first { calendar.isDate($0.date, inSameDayAs: yesterday) }?.didStudy ?? false
        
        // If neither today nor yesterday were studied, the streak is broken
        if !todayStudied && !yesterdayStudied {
            print("❌ Streak broken: Neither today nor yesterday were studied")
            return 0
        }
        
        // Start counting from the most recent studied day
        var expectedDate = todayStudied ? today : yesterday
        
        for day in days {
            let date = day.date.startOfDay
            
            if date > expectedDate { continue }
            if date < expectedDate { break }
            
            if day.didStudy {
                streakCount += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
                print("✅ Found studied day: \(date.formatted()), streak: \(streakCount)")
            } else {
                // Break streak if we find a non-studied day before yesterday
                if !calendar.isDateInToday(date) && !calendar.isDate(date, inSameDayAs: yesterday) {
                    print("❌ Streak broken at: \(date.formatted())")
                    break
                }
            }
        }
        
        return streakCount
    }
}
