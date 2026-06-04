import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var habit: HabitItem?
    
    init(id: UUID = UUID(), date: Date = Date(), isCompleted: Bool = true, habit: HabitItem? = nil) {
        self.id = id
        self.date = date
        self.isCompleted = isCompleted
        self.habit = habit
    }
}
