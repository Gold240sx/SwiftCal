import SwiftUI

struct CalendarGridView: View {
    let days: FetchedResults<Day>
    let currentDate: Date
    let showOnlyMonthDays: Bool
    let dragOffset: CGFloat
    let onDayTap: (Day) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(days) { day in
                if let date = day.date {
                    if showOnlyMonthDays && date.monthInt != currentDate.monthInt {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 40)
                    } else {
                        Text(date.formatted(.dateTime.day()))
                            .fontWeight(.semibold)
                            .foregroundStyle(day.didStudy ? Color.orange :
                                            date.monthInt != currentDate.monthInt ? Color.secondary.opacity(0.3) : .secondary)
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
        }
        .offset(x: dragOffset)
        .opacity(1.0 - (abs(dragOffset) as CGFloat) / 300.0)
    }
} 