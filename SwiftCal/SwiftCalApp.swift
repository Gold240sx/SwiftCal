//
//  SwiftCalApp.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI

@main
struct SwiftCalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                CalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                StreakView()
                    .tabItem { Label("Streak", systemImage: "arrow.triangle.2.circlepath") }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
