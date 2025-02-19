//
//  SwiftCalWidget.swift
//  SwiftCalWidget
//
//  Created by Michael Martell on 2/19/25.
//

import WidgetKit
import SwiftUI
import SwiftData
import Foundation

// Add this if StoreConfig is in a separate module
// import Shared 

struct Provider: TimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Day.self,
                CalendarViewSettings.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                groupContainer: .identifier("group.com.michaelMartell.SwiftCal")
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), days: [], streak: 0, showOnlyMonthDays: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        Task { @MainActor in
            let currentDate = Date()
            let startDate = currentDate.startOfCalendarWithPrefixDays
            let endDate = currentDate.endOfCalendarWithSuffixDays
            
            // Fetch days
            let daysDescriptor = FetchDescriptor<Day>(
                predicate: #Predicate<Day> { day in
                    day.date >= startDate && day.date <= endDate
                },
                sortBy: [SortDescriptor(\Day.date)]
            )
            
            // Fetch settings
            let settingsDescriptor = FetchDescriptor<CalendarViewSettings>()
            
            do {
                let days = try modelContainer.mainContext.fetch(daysDescriptor)
                let settings = try modelContainer.mainContext.fetch(settingsDescriptor)
                let showOnlyMonthDays = settings.first?.showOnlyMonthDays ?? false
                let streak = Calculations.getStreakValue(context: modelContainer.mainContext)
                
                let entry = CalendarEntry(
                    date: currentDate,
                    days: days,
                    streak: streak,
                    showOnlyMonthDays: showOnlyMonthDays
                )
                completion(entry)
            } catch {
                print("❌ Widget failed to fetch: \(error)")
                completion(CalendarEntry(date: currentDate, days: [], streak: 0, showOnlyMonthDays: false))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let currentDate = Date()
            
            // Fetch days
            let daysDescriptor = FetchDescriptor<Day>(
                predicate: #Predicate<Day> { day in
                    day.date >= currentDate.startOfCalendarWithPrefixDays &&
                    day.date <= currentDate.endOfCalendarWithSuffixDays
                },
                sortBy: [SortDescriptor(\Day.date)]
            )
            
            // Fetch settings
            let settingsDescriptor = FetchDescriptor<CalendarViewSettings>()
            
            do {
                let days = try modelContainer.mainContext.fetch(daysDescriptor)
                let settings = try modelContainer.mainContext.fetch(settingsDescriptor)
                let showOnlyMonthDays = settings.first?.showOnlyMonthDays ?? false
                let streak = Calculations.getStreakValue(context: modelContainer.mainContext)
                
                let entry = CalendarEntry(
                    date: currentDate,
                    days: days,
                    streak: streak,
                    showOnlyMonthDays: showOnlyMonthDays
                )
                
                // Update at midnight
                let midnight = Calendar.current.startOfDay(for: currentDate).addingTimeInterval(24 * 60 * 60)
                let timeline = Timeline(entries: [entry], policy: .after(midnight))
                
                completion(timeline)
            } catch {
                print("❌ Widget failed to fetch: \(error)")
                completion(Timeline(entries: [CalendarEntry(date: currentDate, days: [], streak: 0, showOnlyMonthDays: false)], policy: .after(Date())))
            }
        }
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let days: [Day]
    let streak: Int
    let showOnlyMonthDays: Bool
}

struct SwiftCalWidgetEntryView: View {
    var entry: CalendarEntry
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        HStack {
            Link(destination: URL(string: "swiftcal://streak")!) {
                VStack {
                    Text("\(entry.streak)")
                        .font(.system(size: 70, design: .rounded))
                        .bold()
                        .foregroundColor(Color.orange)
                    Text("day streak")
                }
                .offset(x: -6)
            }
            
            Link(destination: URL(string: "swiftcal://calendar")!) {
                VStack {
                    CalendarHeaderView()
                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(entry.days) { day in
                            if entry.showOnlyMonthDays && day.date.monthInt != entry.date.monthInt {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(day.date.formatted(.dateTime.day()))
                                    .font(.caption2)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(day.didStudy ? Color.orange : 
                                        day.date.monthInt != entry.date.monthInt ? Color.secondary.opacity(0.3) : Color.secondary)
                                    .background(
                                        Circle()
                                            .foregroundStyle(day.didStudy ? Color.orange.opacity(0.3) : .clear)
                                            .scaleEffect(1.5)
                                    )
                            }
                        }
                    }
                }
                .padding(.leading, 6)
            }
        }
        .padding()
    }
}

struct SwiftCalWidget: Widget {
    let kind: String = "SwiftCalWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SwiftCalWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SwiftCalWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Swift Study Calendar")
        .description("Track days you study Swift with streaks.")
        .supportedFamilies([.systemMedium])
    }
}

// Preview
#Preview(as: .systemMedium) {
    SwiftCalWidget()
} timeline: {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Day.self, configurations: config)
    let context = container.mainContext
    
    // Create sample days
    let currentDate = Date()
    let startOfMonth = currentDate.startOfMonth

    for dayOffset in 0..<31 {
        let day = Day(date: Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfMonth) ?? startOfMonth)
        day.didStudy = Bool.random()
        context.insert(day)
    }
    
    let days = (try? context.fetch(FetchDescriptor<Day>())) ?? []
    
    return [
        CalendarEntry(date: .now, days: days, streak: 0, showOnlyMonthDays: false),
        CalendarEntry(date: .now, days: days, streak: 3, showOnlyMonthDays: true)
    ]
}
