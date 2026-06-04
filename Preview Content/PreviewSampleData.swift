import Foundation
import SwiftData

@MainActor
struct PreviewSampleData {
    static let container: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            NoteItem.self,
            HabitItem.self,
            HabitLog.self,
            Subject.self,
            StudySession.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            
            let math = Subject(name: "Mathematics", colorHex: "#4A90E2")
            let CS = Subject(name: "Computer Science", colorHex: "#2ECC71")
            
            context.insert(math)
            context.insert(CS)
            
            context.insert(TaskItem(title: "Finish Math Homework", notes: "Review limits and derivatives", dueDate: Date(), priority: .high, isCompleted: false, category: "Study"))
            context.insert(TaskItem(title: "Algorithm Revision", notes: "Red-Black Tree balance cases", dueDate: Date().addingTimeInterval(86400), priority: .medium, isCompleted: false, category: "Study"))
            context.insert(TaskItem(title: "Read Book Chapter 3", notes: "Take down primary sources", dueDate: Date().addingTimeInterval(-3600), priority: .low, isCompleted: true, category: "General"))
            
            context.insert(NoteItem(title: "Calculus Limits", content: "Limit rules are important when working out derivatives.", createdAt: Date(), updatedAt: Date(), category: "Lectures", isPinned: true))
            context.insert(NoteItem(title: "Gemini Integration", content: "To use LLM endpoints, check authorization headers and URL structures.", createdAt: Date().addingTimeInterval(-86400), updatedAt: Date().addingTimeInterval(-86400), category: "Personal", isPinned: false))
            
            let reading = HabitItem(title: "Read Technical Articles", frequency: .daily)
            context.insert(reading)
            let log = HabitLog(date: Date(), isCompleted: true, habit: reading)
            context.insert(log)
            reading.logs.append(log)
            reading.streak = 1
            
            let coding = HabitItem(title: "LeetCode Daily Challenge", frequency: .daily)
            context.insert(coding)
            
            context.insert(StudySession(duration: 1800, date: Date().addingTimeInterval(-7200), notes: "Trigonometry practice problems", subject: math))
            context.insert(StudySession(duration: 3600, date: Date().addingTimeInterval(-86400 * 2), notes: "SwiftData relationships review", subject: CS))
            
            return container
        } catch {
            fatalError("Failed to configure Preview ModelContainer: \(error)")
        }
    }()
}
