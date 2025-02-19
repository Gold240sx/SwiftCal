//
//  SwiftCalApp.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/18/25.
//

import SwiftUI
import SwiftData

@main
struct SwiftCalApp: App {
    let modelContainer: ModelContainer
    @State private var selectedTab: Tab = .calendar
    
    enum Tab {
        case calendar
        case streak
    }
    
    init() {
        do {
            let schema = Schema([
                Day.self,
                CalendarViewSettings.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                groupContainer: .identifier("group.com.michaelMartell.SwiftCal")
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(Tab.calendar)
                
                StreakView()
                    .tabItem {
                        Label("Streak", systemImage: "flame")
                    }
                    .tag(Tab.streak)
            }
            .modelContainer(modelContainer)
            .onOpenURL { url in
                switch url.host {
                case "calendar":
                    selectedTab = .calendar
                case "streak":
                    selectedTab = .streak
                default:
                    break
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Day.self, CalendarViewSettings.self], inMemory: true)
}
