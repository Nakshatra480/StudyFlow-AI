import SwiftUI
import SwiftData

@main
struct StudyFlowAIApp: App {
    @AppStorage("settings_dark_mode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .modelContainer(for: [
                    TaskItem.self,
                    NoteItem.self,
                    HabitItem.self,
                    HabitLog.self,
                    Subject.self,
                    StudySession.self
                ])
        }
    }
}
