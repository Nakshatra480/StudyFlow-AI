import Foundation
import SwiftData

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
}

@Model
final class HabitItem {
    var id: UUID
    var title: String
    var frequency: HabitFrequency
    var createdAt: Date
    var streak: Int
    
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]
    
    init(id: UUID = UUID(), title: String, frequency: HabitFrequency = .daily, createdAt: Date = Date(), streak: Int = 0) {
        self.id = id
        self.title = title
        self.frequency = frequency
        self.createdAt = createdAt
        self.streak = streak
        self.logs = []
    }
}
