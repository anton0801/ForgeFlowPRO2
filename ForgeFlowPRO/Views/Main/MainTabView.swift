import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)
            
            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(2)
            
            ChecklistsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.clipboard")
                }
                .tag(3)
            
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "FF6B35"))
    }
}
