//
//  StreakView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import CoreData

struct StreakView: View {
    @State private var streakValue = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: false)],
        predicate: NSPredicate(format: "date <= %@", Date().endOfDay as CVarArg)
    ) private var days: FetchedResults<Day>
    
    var body: some View {
        VStack {
            Text("\(streakValue)")
                .font(.system(size: 90, weight: .semibold, design: .rounded))
                .foregroundStyle(streakValue > 0 ? .orange : .pink)
            Text("Current Streak")
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
           
        }.offset(y: -20)
            .onAppear { streakValue = calculateStreakValue() }
            .onChange(of: days.count) { 
                streakValue = calculateStreakValue()
            }
    }
    
    func calculateStreakValue() -> Int {
        guard !days.isEmpty else { return 0 }
        
        var streakCount = 0
        var expectedDate = Date().startOfDay // Start from today
        
        for day in days {
            guard let date = day.date?.startOfDay else { continue }
            
            // If this day is after our expected date, skip it (future date)
            if date > expectedDate { continue }
            
            // If this day is before our expected date, we've missed a day
            if date < expectedDate {
                break
            }
            
            // This is the day we're expecting
            if day.didStudy {
                streakCount += 1
                // Set up the next expected date
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                // If we didn't study on this day, break the streak
                // (unless it's today, we still have time today)
                if !Calendar.current.isDateInToday(date) {
                    break
                }
            }
        }
        
        return streakCount
    }
    
    static func getStreakValue(context: NSManagedObjectContext) -> Int {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "date <= %@", Date().endOfDay as CVarArg)
        
        guard let days = try? context.fetch(fetchRequest), !days.isEmpty else { return 0 }
        
        var streakCount = 0
        var expectedDate = Date().startOfDay // Start from today
        
        for day in days {
            guard let date = day.date?.startOfDay else { continue }
            
            // If this day is after our expected date, skip it (future date)
            if date > expectedDate { continue }
            
            // If this day is before our expected date, we've missed a day
            if date < expectedDate {
                break
            }
            
            // This is the day we're expecting
            if day.didStudy {
                streakCount += 1
                // Set up the next expected date
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                // If we didn't study on this day, break the streak
                // (unless it's today, we still have time today)
                if !Calendar.current.isDateInToday(date) {
                    break
                }
            }
        }
        
        return streakCount
    }
}

#Preview {
    StreakView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
