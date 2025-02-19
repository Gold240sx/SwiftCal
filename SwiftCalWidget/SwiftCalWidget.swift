//
//  SwiftCalWidget.swift
//  SwiftCalWidget
//
//  Created by Michael Martell on 2/19/25.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    let viewContext = PersistenceController.shared.container.viewContext
    
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), days: [], streak: 0, showOnlyMonthDays: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let currentDate = Date()
        let calendarFetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        calendarFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: true)]
        calendarFetchRequest.predicate = NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            currentDate.startOfCalendarWithPrefixDays as CVarArg,
            currentDate.endOfCalendarWithSuffixDays as CVarArg
        )
        
        // Fetch settings
        let settingsFetchRequest: NSFetchRequest<CalendarViewSettings> = CalendarViewSettings.fetchRequest()
        let showOnlyMonthDays = (try? viewContext.fetch(settingsFetchRequest).first?.showOnlyMonthDays) ?? false
        
        // Calculate streak
        let streak = Calculations.getStreakValue(context: viewContext)
        
        do {
            let days = try viewContext.fetch(calendarFetchRequest)
            let entry = CalendarEntry(date: currentDate, days: days, streak: streak, showOnlyMonthDays: showOnlyMonthDays)
            completion(entry)
        } catch {
            print("❌ Widget failed to fetch days: \(error)")
            completion(CalendarEntry(date: currentDate, days: [], streak: 0, showOnlyMonthDays: false))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let calendarFetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        calendarFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: true)]
        calendarFetchRequest.predicate = NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            currentDate.startOfCalendarWithPrefixDays as CVarArg,
            currentDate.endOfCalendarWithSuffixDays as CVarArg
        )
        
        // Fetch settings
        let settingsFetchRequest: NSFetchRequest<CalendarViewSettings> = CalendarViewSettings.fetchRequest()
        let showOnlyMonthDays = (try? viewContext.fetch(settingsFetchRequest).first?.showOnlyMonthDays) ?? false
        
        // Calculate streak
        let streak = Calculations.getStreakValue(context: viewContext)
        
        do {
            let days = try viewContext.fetch(calendarFetchRequest)
            let entry = CalendarEntry(date: currentDate, days: days, streak: streak, showOnlyMonthDays: showOnlyMonthDays)
            
            // Update at midnight
            let midnight = Calendar.current.startOfDay(for: currentDate).addingTimeInterval(24 * 60 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(midnight))
            
            print("📊 Widget found \(days.count) days, streak: \(streak), showOnlyMonthDays: \(showOnlyMonthDays)")
            completion(timeline)
        } catch {
            print("❌ Widget failed to fetch days: \(error)")
            completion(Timeline(entries: [CalendarEntry(date: currentDate, days: [], streak: 0, showOnlyMonthDays: false)], policy: .after(Date())))
        }
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let days: [Day]
    let streak: Int
    let showOnlyMonthDays: Bool
}

struct SwiftCalWidgetEntryView : View {
    var entry: CalendarEntry
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        HStack {
            Link(destination: URL(string: "streak")!) {
                VStack {
                    Text("\(entry.streak)")
                        .font(.system(size: 70, design: .rounded))
                        .bold()
                        .foregroundColor(Color.orange)
                    Text("day streak")
                }
                .offset(x: -6)
            }
            Link(destination: URL(string: "calendar")!) {
                VStack {
                    CalendarHeaderView()
                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(entry.days) { day in
                            if entry.showOnlyMonthDays && day.date!.monthInt != entry.date.monthInt {
                                Text("")
                            } else {
                                Text(day.date!.formatted(.dateTime.day()))
                                    .font(.caption2)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(day.didStudy ? Color.orange : 
                                        day.date!.monthInt != entry.date.monthInt ? Color.secondary.opacity(0.3) : Color.secondary)
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

#Preview(as: .systemMedium) {
    SwiftCalWidget()
} timeline: {
    CalendarEntry(date: .now, days: [], streak: 0, showOnlyMonthDays: false)
    CalendarEntry(date: .now, days: [], streak: 3, showOnlyMonthDays: true)
}
