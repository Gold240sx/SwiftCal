//
//  SwiftCalWidget.swift
//  SwiftCalWidget
//
//  Created by Sean Allen on 8/23/22.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), days: [])
    }

    @MainActor func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let entry = CalendarEntry(date: Date(), days: fetchDays())
        completion(entry)
    }

    @MainActor func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = CalendarEntry(date: Date(), days: fetchDays())
        let timeline = Timeline(entries: [entry], policy: .after(.now.endOfDay))
        completion(timeline)
    }

    @MainActor func fetchDays() -> [Day] {
        var sharedStoreURL: URL {
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.co.seanallen.SwiftCal")!
            return container.appendingPathComponent("SwiftCal.sqlite")
        }

        let container: ModelContainer = {
            let config = ModelConfiguration(url: sharedStoreURL)
            return try! ModelContainer(for: Day.self, configurations: config)
        }()

        let startDate = Date().startOfCalendarWithPrefixDays
        let endDate = Date().endOfMonth
        
        let predicate = #Predicate<Day> { $0.date > startDate && $0.date < endDate }
        let desciptor = FetchDescriptor<Day>(predicate: predicate, sortBy: [.init(\.date)])

        return try! container.mainContext.fetch(desciptor)
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let days: [Day]
}

struct SwiftCalWidgetEntryView : View {
    var entry: CalendarEntry
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        HStack {
            Link(destination: URL(string: "streak")!) {
                VStack {
                    Text("\(calculateStreakValue())")
                        .font(.system(size: 70, design: .rounded))
                        .bold()
                        .foregroundColor(.orange)

                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Link(destination: URL(string: "calendar")!) {
                VStack {
                    CalendarHeaderView(font: .caption)

                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(entry.days) { day in
                            if day.date.monthInt != Date().monthInt {
                                Text(" ")
                            } else {
                                Text(day.date.formatted(.dateTime.day()))
                                    .font(.caption2)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(day.didStudy ? .orange : .secondary)
                                    .background(
                                        Circle()
                                            .foregroundColor(.orange.opacity(day.didStudy ? 0.3 : 0.0))
                                            .scaleEffect(1.5)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.leading, 6)
        }
        .padding()
    }

    func calculateStreakValue() -> Int {
        guard !entry.days.isEmpty else { return 0 }

        let nonFutureDays = entry.days.filter { $0.date.dayInt <= Date().dayInt }

        var streakCount = 0

        for day in nonFutureDays.reversed() {
            if day.didStudy {
                streakCount += 1
            } else {
                if day.date.dayInt != Date().dayInt {
                    break
                }
            }
        }

        return streakCount
    }
}

@main
struct SwiftCalWidget: Widget {
    let kind: String = "SwiftCalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SwiftCalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Swift Study Calendar")
        .description("Track days you study Swift with streaks.")
        .supportedFamilies([.systemMedium])
    }
}

struct SwiftCalWidget_Previews: PreviewProvider {

    static var previews: some View {
        SwiftCalWidgetEntryView(entry: CalendarEntry(date: Date(), days: []))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
