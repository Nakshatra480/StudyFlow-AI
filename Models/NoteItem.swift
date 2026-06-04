import Foundation
import SwiftData

@Model
final class NoteItem {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var category: String
    var isPinned: Bool
    
    init(id: UUID = UUID(), title: String, content: String = "", createdAt: Date = Date(), updatedAt: Date = Date(), category: String = "General", isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
        self.isPinned = isPinned
    }
}
