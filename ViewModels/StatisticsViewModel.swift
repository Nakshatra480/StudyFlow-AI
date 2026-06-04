import Foundation
import SwiftData

struct SessionStats: Identifiable {
    var id = UUID()
    let subjectName: String
    let hours: Double
    let colorHex: String
}

struct TaskStats: Identifiable {
    var id = UUID()
    let dayOfWeek: String
    let count: Int
}

struct HabitStats: Identifiable {
    var id = UUID()
    let habitName: String
    let completionRate: Double
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    func getStudyHoursPerSubject(subjects: [Subject]) -> [SessionStats] {
        subjects.map { subject in
            let totalSeconds = subject.sessions.reduce(0.0) { $0 + $1.duration }
            let hours = totalSeconds / 3600.0
            return SessionStats(subjectName: subject.name, hours: hours, colorHex: subject.colorHex)
        }
    }
    
    func getTasksCompletedPastWeek(tasks: [TaskItem]) -> [TaskStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var stats: [TaskStats] = []
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        
        for i in (0..<7).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let start = calendar.startOfDay(for: targetDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            
            let count = tasks.filter { $0.isCompleted && $0.dueDate >= start && $0.dueDate < end }.count
            let dayName = dayFormatter.string(from: start)
            stats.append(TaskStats(dayOfWeek: dayName, count: count))
        }
        
        return stats
    }
    
    func getHabitCompletionRates(habits: [HabitItem]) -> [HabitStats] {
        habits.map { habit in
            let totalDays = max(1.0, Double(Calendar.current.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 1))
            let completions = Double(habit.logs.count)
            let rate = min(1.0, completions / totalDays)
            return HabitStats(habitName: habit.title, completionRate: rate)
        }
    }
}
