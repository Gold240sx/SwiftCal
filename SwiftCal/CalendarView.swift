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
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(
            format: "(date >= %@) AND (date <= %@)",
            Date().startOfCalendarWithPrefixDays as CVarArg,
            Date().endOfCalendarWithSuffixDays as CVarArg )
        )
    private var days: FetchedResults<Day>
    
    @FetchRequest(
        sortDescriptors: []
    ) private var settings: FetchedResults<CalendarViewSettings>
    
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    @State private var showingSettings = false

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

    var body: some View {
        NavigationView {
            VStack() {
                HStack {
                    ForEach(daysOfWeek, id: \.self) { daysOfWeek in
                        Text(daysOfWeek)
                            .fontWeight(.black)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(days) { day in
                        if !showOnlyMonthDays || day.date!.monthInt == Date().monthInt {
                            Text(day.date!.formatted(.dateTime.day()))
                                .fontWeight(.semibold)
                                .foregroundStyle(day.didStudy ? .orange :
                                                    day.date!.monthInt != Date().monthInt ? .secondary.opacity(0.3) : .secondary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    Circle()
                                        .foregroundStyle(.orange.opacity(day.didStudy ? 0.3 : 0.0))
                                )
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle(Date().formatted(.dateTime.month(.wide)))
            .toolbar {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(.orange)
                }
            }
            .padding()
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    Form {
                        Toggle("Show Current Month Only", isOn: showOnlyMonthDaysBinding)
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
                    createMonthDays(for: .now.startOfPreviousMonth)
                    createMonthDays(for: .now)
                    createMonthDays(for: .now.startOfNextMonth)
                } else if days.count < 10 { // Is only the prefix days
                    createMonthDays(for: .now)
                    createMonthDays(for: .now.startOfNextMonth)
                }
                if settings.isEmpty {
                    let newSettings = CalendarViewSettings(context: viewContext)
                    newSettings.showOnlyMonthDays = false // default value
                    try? viewContext.save()
                }
            }
        }
    }
    
    func createMonthDays(for date: Date) {
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

#Preview {
    CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
