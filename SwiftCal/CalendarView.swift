//
//  ContentView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import CoreData
import WidgetKit

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: []
    ) private var settings: FetchedResults<CalendarViewSettings>
    @FetchRequest private var days: FetchedResults<Day>
    
    @State private var showingSettings = false
    @State private var currentDate = Date()
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    init() {
        // Start with current date's calendar range
        let currentDate = Date()
        _days = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
            predicate: NSPredicate(
                format: "(date >= %@) AND (date <= %@)",
                currentDate.startOfCalendarWithPrefixDays as CVarArg,
                currentDate.endOfCalendarWithSuffixDays as CVarArg
            )
        )
    }

    private var showOnlyMonthDays: Bool {
        settings.first?.showOnlyMonthDays ?? false
    }

    private var showOnlyMonthDaysBinding: Binding<Bool> {
        Binding(
            get: { settings.first?.showOnlyMonthDays ?? false },
            set: { newValue in
                if let settings = settings.first {
                    settings.showOnlyMonthDays = newValue
                    do {
                        try viewContext.save()
                        // Reload widget to reflect the new setting
                        WidgetCenter.shared.reloadTimelines(ofKind: "SwiftCalWidget")
                    } catch {
                        print("Failed to save settings: \(error)")
                    }
                }
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
                    try? viewContext.save()
                }
            }
        )
    }

    private func updateDaysFetchRequest() {
        days.nsPredicate = NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            currentDate.startOfCalendarWithPrefixDays as CVarArg,
            currentDate.endOfCalendarWithSuffixDays as CVarArg
        )
    }

    private func handleDayTap(_ day: Day) {
        if day.date!.monthInt != currentDate.monthInt {
            currentDate = day.date!
            createMonthDays(for: currentDate.startOfPreviousMonth)
            createMonthDays(for: currentDate)
            createMonthDays(for: currentDate.startOfNextMonth)
            updateDaysFetchRequest()
        } else if day.date! < Date().startOfTomorrow {
            day.didStudy.toggle()
            do {
                try viewContext.save()
                WidgetCenter.shared.reloadTimelines(ofKind: "SwiftCalWidget")
                
                // Fetch the days and calculate streak
                let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: false)]
                fetchRequest.predicate = NSPredicate(format: "date <= %@", Date().endOfDay as CVarArg)
                
                if let days = try? viewContext.fetch(fetchRequest) {
                    let streak = Calculations.calculateStreakValue(days: days)
                    print("👆 \(day.date!.dayInt) now studied. Current streak: \(streak) days")
                }
            } catch {
                print("Failed to save context: \(error)")
            }
        } else {
            print("Can't study in the future!!")
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                CalendarHeaderView()
                
                CalendarGridView(
                    days: days,
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
                                        updateDaysFetchRequest()
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
                                updateDaysFetchRequest()
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
                                updateDaysFetchRequest()
                            } label: {
                                Text("Today")
                                    .foregroundStyle(.orange)
                            }
                            
                            Button {
                                currentDate = currentDate.startOfNextMonth
                                createMonthDays(for: currentDate.startOfPreviousMonth)
                                createMonthDays(for: currentDate)
                                createMonthDays(for: currentDate.startOfNextMonth)
                                updateDaysFetchRequest()
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
                // Always update the fetch request to show current month
                updateDaysFetchRequest()
                
                if settings.isEmpty {
                    let newSettings = CalendarViewSettings(context: viewContext)
                    newSettings.showOnlyMonthDays = false
                    newSettings.showMonthCarots = true
                    try? viewContext.save()
                }
            }
        }
    }
    
    private func daysExist(for date: Date) -> Bool {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            date.startOfMonth as CVarArg,
            date.endOfMonth as CVarArg
        )
        let count = (try? viewContext.count(for: fetchRequest)) ?? 0
        return count > 0
    }

    func createMonthDays(for date: Date) {
        if !daysExist(for: date) {
            // Get the start and end of the month
            let startOfMonth = date.startOfMonth
            let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            
            // Create a day for each date in the month
            var currentDate = startOfMonth
            while currentDate <= endOfMonth {
                let newDay = Day(context: viewContext)
                newDay.date = currentDate
                newDay.didStudy = false
                
                // Move to next day
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            do {
                try viewContext.save()
                print("\(date.monthFullName) \(date.yearInt) days created")
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    private func cleanupDuplicateDays(for date: Date) {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            date.startOfMonth as CVarArg,
            date.endOfMonth as CVarArg
        )
        
        do {
            let existingDays = try viewContext.fetch(fetchRequest)
            var seenDates: [Date: Day] = [:]
            
            for day in existingDays {
                if let dayDate = day.date {
                    if seenDates[dayDate] != nil {
                        viewContext.delete(day)
                    } else {
                        seenDates[dayDate] = day
                    }
                }
            }
            
            try viewContext.save()
        } catch {
            print("Failed to cleanup duplicate days: \(error)")
        }
    }
}

#Preview {
    CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
