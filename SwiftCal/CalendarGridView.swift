import SwiftUI
import SwiftData

struct CalendarGridView: View {
    let days: [Day]
    let currentDate: Date
    let showOnlyMonthDays: Bool
    let dragOffset: CGFloat
    let onDayTap: (Day) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(days) { day in
                if showOnlyMonthDays && day.date.monthInt != currentDate.monthInt {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 40)
                } else {
                    Text(day.date.formatted(.dateTime.day()))
                        .fontWeight(.semibold)
                        .foregroundStyle(day.didStudy ? Color.orange :
                            day.date.monthInt != currentDate.monthInt ? Color.secondary.opacity(0.3) : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            Circle()
                                .foregroundStyle(Color.orange.opacity(day.didStudy ? 0.3 : 0.0))
                        )
                        .onTapGesture {
                            onDayTap(day)
                        }
                }
            }
        }
        .offset(x: dragOffset)
        .opacity(1.0 - (abs(dragOffset) as CGFloat) / 300.0)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Day.self, configurations: config)
    
    // Create some sample days
    let context = container.mainContext
    let currentDate = Date()
    
    for dayOffset in -5...35 {
        let day = Day()
        day.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentDate.startOfMonth)!
        day.didStudy = Bool.random()
        context.insert(day)
    }
    
    return CalendarGridView(
        days: (try? context.fetch(FetchDescriptor<Day>()))!,
        currentDate: currentDate,
        showOnlyMonthDays: false,
        dragOffset: 0,
        onDayTap: { _ in }
    )
    .modelContainer(container)
} 