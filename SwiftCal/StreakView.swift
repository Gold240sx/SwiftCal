//
//  StreakView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import CoreData

struct StreakView: View {
    @State private var streakValue = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: false)],
        predicate: NSPredicate(format: "date <= %@", Date().endOfDay as CVarArg)
    ) private var days: FetchedResults<Day>
    
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
                streakValue = Calculations.calculateStreakValue(days: Array(days))
            }
            .onChange(of: days.count) { 
                streakValue = Calculations.calculateStreakValue(days: Array(days))
            }
    }
}

#Preview {
    StreakView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
