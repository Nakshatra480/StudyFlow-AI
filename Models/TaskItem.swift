import Foundation
import SwiftData

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var priority: TaskPriority
    var isCompleted: Bool
    var category: String
    
    init(id: UUID = UUID(), title: String, notes: String = "", dueDate: Date = Date(), priority: TaskPriority = .medium, isCompleted: Bool = false, category: String = "General") {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.category = category
    }
}
