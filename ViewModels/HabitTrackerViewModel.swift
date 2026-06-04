import Foundation
import SwiftData

@MainActor
final class HabitTrackerViewModel: ObservableObject {
    func addHabit(title: String, frequency: HabitFrequency, context: ModelContext) {
        let habit = HabitItem(title: title, frequency: frequency)
        context.insert(habit)
        try? context.save()
    }
    
    func deleteHabit(_ habit: HabitItem, context: ModelContext) {
        context.delete(habit)
        try? context.save()
    }
    
    func toggleHabitCompletion(_ habit: HabitItem, date: Date, context: ModelContext) {
        let calendar = Calendar.current
        let logIndex = habit.logs.firstIndex { calendar.isDate($0.date, inSameDayAs: date) }
        
        if let idx = logIndex {
            let log = habit.logs[idx]
            context.delete(log)
            habit.logs.remove(at: idx)
            recalculateStreak(for: habit)
        } else {
            let newLog = HabitLog(date: date, isCompleted: true, habit: habit)
            context.insert(newLog)
            habit.logs.append(newLog)
            recalculateStreak(for: habit)
        }
        try? context.save()
    }
    
    func isHabitCompletedToday(_ habit: HabitItem) -> Bool {
        let calendar = Calendar.current
        return habit.logs.contains { calendar.isDate($0.date, inSameDayAs: Date()) }
    }
    
    private func recalculateStreak(for habit: HabitItem) {
        let calendar = Calendar.current
        let completedDates = Set(habit.logs.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) })
        
        guard !completedDates.isEmpty else {
            habit.streak = 0
            return
        }
        
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        if !completedDates.contains(checkDate) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                checkDate = yesterday
            }
        }
        
        while completedDates.contains(checkDate) {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        habit.streak = currentStreak
    }
}
