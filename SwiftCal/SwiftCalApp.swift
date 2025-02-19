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
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView (selection: $selectedTab) {
               CalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                    .tag(0)
                StreakView()
                    .tabItem { Label("Streak", systemImage: "arrow.triangle.2.circlepath") }
                    .tag(1)
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onOpenURL { url in
                selectedTab = url.absoluteString == "calendar" ? 0 : 1
            }
        }
    }
}

//
//#Preview {
//    SwiftCalApp()
//}
