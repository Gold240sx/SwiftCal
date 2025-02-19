//
//  StreakView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import SwiftData

struct StreakView: View {
    @Environment(\.modelContext) private var context
    @State private var streakValue = 0
    
    @Query(sort: [SortDescriptor(\Day.date, order: .reverse)]) private var allDays: [Day]
    private var days: [Day] {
        allDays.filter { $0.date <= Date().endOfDay }
    }
    
    var body: some View {
        VStack {
            Text("\(streakValue)")
                .font(.system(size: 90, weight: .semibold, design: .rounded))
                .foregroundStyle(streakValue > 0 ? .orange : .pink)
            Text("Current Streak")
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
           
        }.offset(y: -20)
            .onAppear { 
                streakValue = Calculations.calculateStreakValue(days: days)
            }
            .onChange(of: days.count) { 
                streakValue = Calculations.calculateStreakValue(days: days)
            }
    }
}

#Preview {
    StreakView()
        .modelContainer(for: Day.self, inMemory: true)
}
