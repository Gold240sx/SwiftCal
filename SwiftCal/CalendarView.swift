//
//  ContentView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @State private var currentDate = Date()
    
    // Remove the queryDateRange state and use computed properties
    private var startDate: Date {
        currentDate.startOfCalendarWithPrefixDays
    }
    
    private var endDate: Date {
        currentDate.endOfCalendarWithSuffixDays
    }
    
    // Use computed property for the query
    @Query(sort: \Day.date) private var allDays: [Day]
    private var days: [Day] {
        allDays.filter { day in
            day.date >= startDate && day.date <= endDate
        }
    }
    
    @Query private var settings: [CalendarViewSettings]
    
    @State private var showingSettings = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private var showOnlyMonthDays: Bool {
        settings.first?.showOnlyMonthDays ?? false
    }

    private var showOnlyMonthDaysBinding: Binding<Bool> {
        Binding(
            get: { settings.first?.showOnlyMonthDays ?? false },
            set: { newValue in
                if let settings = settings.first {
                    settings.showOnlyMonthDays = newValue
                    // Force widget to update immediately
                    WidgetCenter.shared.reloadAllTimelines()
                } else {
                    let newSettings = CalendarViewSettings()
                    newSettings.showOnlyMonthDays = newValue
                    context.insert(newSettings)
                    // Force widget to update immediately
                    WidgetCenter.shared.reloadAllTimelines()
                }
                   WidgetCenter.shared.reloadAllTimelines()
            }
        )
    }

    private var showMonthCarots: Bool {
        settings.first?.showMonthCarots ?? true
    }

    private var showMonthCarotsBinding: Binding<Bool> {
        Binding(
            get: { settings.first?.showMonthCarots ?? true },
            set: { newValue in
                if let settings = settings.first {
                    settings.showMonthCarots = newValue
                } else {
                    let newSettings = CalendarViewSettings()
                    newSettings.showMonthCarots = newValue
                    context.insert(newSettings)
                }
            }
        )
    }

    private func handleDayTap(_ day: Day) {
        if day.date.monthInt != currentDate.monthInt {
            currentDate = day.date
            createMonthDays(for: currentDate.startOfPreviousMonth)
            createMonthDays(for: currentDate)
            createMonthDays(for: currentDate.startOfNextMonth)
          WidgetCenter.shared.reloadAllTimelines()
       } else if day.date < Date().startOfTomorrow {
            day.didStudy.toggle()
            // Force widget to update
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("Can't study in the future!!")
        }
           WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        NavigationView {
            VStack {
                CalendarHeaderView()
                
                CalendarGridView(
                    days: days,  // This will automatically update when currentDate changes
                    currentDate: currentDate,
                    showOnlyMonthDays: showOnlyMonthDays,
                    dragOffset: dragOffset,
                    onDayTap: handleDayTap
                )
                Spacer()
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onChanged { gesture in
                        isDragging = true
                        dragOffset = gesture.translation.width
                    }
                    .onEnded { gesture in
                        let horizontalAmount = gesture.translation.width
                        let verticalAmount = gesture.translation.height
                        
                        // Only respond to mostly horizontal swipes
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            let threshold: CGFloat = 50
                            
                            if horizontalAmount < -threshold {  // Swipe left
                                if currentDate.startOfMonth < Date().endOfNextAllowedYear {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        dragOffset = -UIScreen.main.bounds.width
                                        currentDate = currentDate.startOfNextMonth
                                    }
                                    
                                    // After animation, reset and update
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        dragOffset = UIScreen.main.bounds.width
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            dragOffset = 0
                                        }
                                    }
                                } else {
                                    withAnimation { dragOffset = 0 }
                                }
                            } else if horizontalAmount > threshold {  // Swipe right
                                if currentDate.startOfMonth > Date().startOfPreviousAllowedYear {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        dragOffset = UIScreen.main.bounds.width
                                        currentDate = currentDate.startOfPreviousMonth
                                    }
                                    
                                    // After animation, reset and update
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        dragOffset = -UIScreen.main.bounds.width
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            dragOffset = 0
                                        }
                                        createMonthDays(for: currentDate.startOfPreviousMonth)
                                        createMonthDays(for: currentDate)
                                        createMonthDays(for: currentDate.startOfNextMonth)
                                    }
                                } else {
                                    withAnimation { dragOffset = 0 }
                                }
                            } else {
                                withAnimation { dragOffset = 0 }
                            }
                        } else {
                            withAnimation { dragOffset = 0 }
                        }
                        
                        isDragging = false
                    }
            )
            .navigationTitle(currentDate.formatted(.dateTime.month(.wide).year()))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        if showMonthCarots {
                            Button {
                                currentDate = currentDate.startOfPreviousMonth
                                createMonthDays(for: currentDate.startOfPreviousMonth)
                                createMonthDays(for: currentDate)
                                createMonthDays(for: currentDate.startOfNextMonth)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.orange)
                            }
                            .disabled(currentDate.startOfMonth <= Date().startOfPreviousAllowedYear)
                            
                            Button {
                                currentDate = Date()
                                createMonthDays(for: currentDate.startOfPreviousMonth)
                                createMonthDays(for: currentDate)
                                createMonthDays(for: currentDate.startOfNextMonth)
                            } label: {
                                Text("Today")
                                    .foregroundStyle(.orange)
                            }
                            
                            Button {
                                currentDate = currentDate.startOfNextMonth
                                createMonthDays(for: currentDate.startOfPreviousMonth)
                                createMonthDays(for: currentDate)
                                createMonthDays(for: currentDate.startOfNextMonth)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.orange)
                            }
                            .disabled(currentDate.startOfMonth >= Date().endOfNextAllowedYear)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding()
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    Form {
                        Toggle("Hide Days of Previous and Next Months", isOn: showOnlyMonthDaysBinding)
                        Toggle("Show Month Navigation", isOn: showMonthCarotsBinding)
                    }
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        Button("Done") {
                            showingSettings = false
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                if days.isEmpty {
                    // Create days from start of previous year to end of next year
                    var date = Date().startOfPreviousAllowedYear
                    while date <= Date().endOfNextAllowedYear {
                        createMonthDays(for: date)
                        date = date.startOfNextMonth
                    }
                }
                
                if settings.isEmpty {
                    let newSettings = CalendarViewSettings()
                    newSettings.showOnlyMonthDays = false
                    newSettings.showMonthCarots = true
                    context.insert(newSettings)
                }
            }
        }
    }
    
    private func daysExist(for date: Date) -> Bool {
        let monthStart = date.startOfMonth
        let monthEnd = date.endOfMonth
        
        let descriptor = FetchDescriptor<Day>(
            predicate: #Predicate<Day> { day in
                day.date >= monthStart && day.date <= monthEnd
            }
        )
        
        do {
            let existingDays = try context.fetch(descriptor)
            return !existingDays.isEmpty
        } catch {
            print("Failed to check if days exist: \(error)")
            return false
        }
    }

    private func createMonthDays(for date: Date) {
        let daysInMonth = date.numberOfDaysInMonth
        let firstDayOfMonth = date.startOfMonth
        let nextMonthStart = Calendar.current.date(byAdding: .month, value: 1, to: firstDayOfMonth)!
        
        let descriptor = FetchDescriptor<Day>(
            predicate: #Predicate<Day> { day in
                day.date >= firstDayOfMonth && day.date < nextMonthStart
            }
        )
        
        do {
            let existingDays = try context.fetch(descriptor)
            var seenDates: [Date: Day] = [:]
            
            // Create days for the month
            for dayOffset in 0..<daysInMonth {
                let newDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth)!
                
                if let existingDay = existingDays.first(where: { Calendar.current.isDate($0.date, inSameDayAs: newDate) }) {
                    seenDates[newDate.startOfDay] = existingDay
                } else {
                    let day = Day(date: newDate)
                    context.insert(day)
                    seenDates[newDate.startOfDay] = day
                }
            }
            
            // Remove duplicates
            for day in existingDays {
                if seenDates[day.date.startOfDay] != day {
                    context.delete(day)
                }
            }
            
        } catch {
            print("Failed to cleanup duplicate days: \(error)")
        }
    }

    private func cleanupDuplicateDays(for date: Date) {
        let monthStart = date.startOfMonth
        let monthEnd = date.endOfMonth
        
        let descriptor = FetchDescriptor<Day>(
            predicate: #Predicate<Day> { day in
                day.date >= monthStart && day.date <= monthEnd
            }
        )
        
        do {
            let existingDays = try context.fetch(descriptor)
            var seenDates: [Date: Day] = [:]
            
            for day in existingDays {
                if seenDates[day.date.startOfDay] != nil {
                    context.delete(day)
                } else {
                    seenDates[day.date.startOfDay] = day
                }
            }
        } catch {
            print("Failed to cleanup duplicate days: \(error)")
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Day.self, CalendarViewSettings.self], inMemory: true)
}
