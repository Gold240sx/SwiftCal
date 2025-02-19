import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let streak = WidgetPersistence.shared.getCurrentStreak()
        let entry = SimpleEntry(date: Date(), streak: streak)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let streak = WidgetPersistence.shared.getCurrentStreak()
        let entry = SimpleEntry(date: Date(), streak: streak)
        
        // Update at the start of next day
        let nextUpdate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct SwiftCalWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("\(entry.streak)")
                .font(.system(size: 40, weight: .bold))
            Text("Day Streak")
                .font(.caption)
        }
    }
}

@main
struct SwiftCalWidget: Widget {
    let kind: String = "SwiftCalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SwiftCalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Study Streak")
        .description("Shows your current study streak.")
        .supportedFamilies([.systemSmall])
    }
} 