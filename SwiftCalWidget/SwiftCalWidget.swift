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
<<<<<<< HEAD
        CalendarEntry(date: Date(), days: [], streak: 0)
=======
        CalendarEntry(date: Date(), days: [], streak: 0, showOnlyMonthDays: false)
>>>>>>> 665bf18 (Update)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        // Fetch days for calendar display
        let currentDate = Date()
        let calendarFetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        calendarFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: true)]
        calendarFetchRequest.predicate = NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            currentDate.startOfCalendarWithPrefixDays as CVarArg,
            currentDate.endOfCalendarWithSuffixDays as CVarArg
        )
        
<<<<<<< HEAD
=======
        // Fetch settings
        let settingsFetchRequest: NSFetchRequest<CalendarViewSettings> = CalendarViewSettings.fetchRequest()
        let showOnlyMonthDays = (try? viewContext.fetch(settingsFetchRequest).first?.showOnlyMonthDays) ?? false
        
>>>>>>> 665bf18 (Update)
        // Calculate streak
        let streak = Calculations.getStreakValue(context: viewContext)
        
        do {
            let days = try viewContext.fetch(calendarFetchRequest)
<<<<<<< HEAD
            let entry = CalendarEntry(date: currentDate, days: days, streak: streak)
            completion(entry)
        } catch {
            print("❌ Widget failed to fetch days: \(error)")
            completion(CalendarEntry(date: currentDate, days: [], streak: 0))
=======
            let entry = CalendarEntry(date: currentDate, days: days, streak: streak, showOnlyMonthDays: showOnlyMonthDays)
            completion(entry)
        } catch {
            print("❌ Widget failed to fetch days: \(error)")
            completion(CalendarEntry(date: currentDate, days: [], streak: 0, showOnlyMonthDays: false))
>>>>>>> 665bf18 (Update)
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
        
<<<<<<< HEAD
=======
        // Fetch settings
        let settingsFetchRequest: NSFetchRequest<CalendarViewSettings> = CalendarViewSettings.fetchRequest()
        let showOnlyMonthDays = (try? viewContext.fetch(settingsFetchRequest).first?.showOnlyMonthDays) ?? false
        
>>>>>>> 665bf18 (Update)
        // Calculate streak
        let streak = Calculations.getStreakValue(context: viewContext)
        
        do {
            let days = try viewContext.fetch(calendarFetchRequest)
<<<<<<< HEAD
            let entry = CalendarEntry(date: currentDate, days: days, streak: streak)
=======
            let entry = CalendarEntry(date: currentDate, days: days, streak: streak, showOnlyMonthDays: showOnlyMonthDays)
>>>>>>> 665bf18 (Update)
            
            // Update at midnight
            let midnight = Calendar.current.startOfDay(for: currentDate).addingTimeInterval(24 * 60 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(midnight))
            
<<<<<<< HEAD
            print("📊 Widget found \(days.count) days, streak: \(streak)")
            completion(timeline)
        } catch {
            print("❌ Widget failed to fetch days: \(error)")
            completion(Timeline(entries: [CalendarEntry(date: currentDate, days: [], streak: 0)], policy: .after(Date())))
=======
            print("📊 Widget found \(days.count) days, streak: \(streak), showOnlyMonthDays: \(showOnlyMonthDays)")
            completion(timeline)
        } catch {
            print("❌ Widget failed to fetch days: \(error)")
            completion(Timeline(entries: [CalendarEntry(date: currentDate, days: [], streak: 0, showOnlyMonthDays: false)], policy: .after(Date())))
>>>>>>> 665bf18 (Update)
        }
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let days: [Day]
    let streak: Int
<<<<<<< HEAD
=======
    let showOnlyMonthDays: Bool
>>>>>>> 665bf18 (Update)
}

struct SwiftCalWidgetEntryView : View {
    var entry: CalendarEntry
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        HStack {
<<<<<<< HEAD
            VStack {
                Text("\(entry.streak)")
                    .font(.system(size: 70, design: .rounded))
                    .bold()
                    .foregroundColor(Color.orange)
                Text("day streak")
            }
            .offset(x: -6)
            
            VStack {
                CalendarHeaderView()
                LazyVGrid(columns: columns, spacing: 7) {
                    ForEach(entry.days) { day in
                        if day.date!.monthInt != Date().monthInt {
                            Text("")
                        } else {
                            Text(day.date!.formatted(.dateTime.day()))
                                .font(.caption2)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(day.didStudy ? Color.orange : Color.secondary)
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
=======
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
>>>>>>> 665bf18 (Update)
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
<<<<<<< HEAD
    CalendarEntry(date: .now, days: [], streak: 0)
    CalendarEntry(date: .now, days: [], streak: 3)
=======
    CalendarEntry(date: .now, days: [], streak: 0, showOnlyMonthDays: false)
    CalendarEntry(date: .now, days: [], streak: 3, showOnlyMonthDays: true)
>>>>>>> 665bf18 (Update)
}
