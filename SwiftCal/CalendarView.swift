//
//  ContentView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: []
    ) private var settings: FetchedResults<CalendarViewSettings>
    @FetchRequest private var days: FetchedResults<Day>
    
    @State private var showingSettings = false
    @State private var currentDate = Date()

    
    private struct WeekDay: Identifiable {
        let id = UUID()
        let name: String
    }

    private let daysOfWeek = [
        WeekDay(name: "S"),
        WeekDay(name: "M"),
        WeekDay(name: "T"),
        WeekDay(name: "W"),
        WeekDay(name: "T"),
        WeekDay(name: "F"),
        WeekDay(name: "S")
    ]

    init() {
        _days = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
            predicate: NSPredicate(
                format: "(date >= %@) AND (date <= %@)",
                Date().startOfCalendarWithPrefixDays as CVarArg,
                Date().endOfCalendarWithSuffixDays as CVarArg
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
                    try? viewContext.save()
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

    var body: some View {
        NavigationView {
            VStack() {
                HStack {
                    ForEach(daysOfWeek) { day in
                        Text(day.name)
                            .fontWeight(.black)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(days) { day in
                        if !showOnlyMonthDays || day.date!.monthInt == currentDate.monthInt {
                            Text(day.date!.formatted(.dateTime.day()))
                                .fontWeight(.semibold)
                                .foregroundStyle(day.didStudy ? Color.orange :
                                                    day.date!.monthInt != currentDate.monthInt ? Color.secondary.opacity(0.3) : .secondary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    Circle()
                                        .foregroundStyle(Color.orange.opacity(day.didStudy ? 0.3 : 0.0))
                                )
                                .onTapGesture {
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
                                            let streak = StreakView.getStreakValue(context: viewContext)
                                            print("👆 \(day.date!.dayInt) now studied. Current streak: \(streak) days")
                                        } catch {
                                            print("Failed to save context: \(error)")
                                        }
                                    } else {
                                        print("Can't study in the future!!")
                                    }
                                }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle(currentDate.formatted(.dateTime.month(.wide)))
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
                    createMonthDays(for: currentDate.startOfPreviousMonth)
                    createMonthDays(for: currentDate)
                    createMonthDays(for: currentDate.startOfNextMonth)
                    updateDaysFetchRequest()
                }
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
            for dayOffset in 0..<date.numberOfDaysInMonth {
                let newDay = Day(context: viewContext)
                newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: date.startOfMonth) ?? Date()
                newDay.didStudy = false
            }
            
            do {
                try viewContext.save()
                print("\(date.monthFullName) days created")
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
