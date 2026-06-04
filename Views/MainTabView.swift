import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
            
            TaskManagerView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            
            StudyPlannerView()
                .tabItem {
                    Label("Study", systemImage: "timer")
                }
            
            HabitTrackerView()
                .tabItem {
                    Label("Habits", systemImage: "calendar")
                }
            
            AIAssistantView()
                .tabItem {
                    Label("AI Assistant", systemImage: "sparkles")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewSampleData.container)
}

