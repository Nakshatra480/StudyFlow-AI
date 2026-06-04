import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var colorHex: String
    
    @Relationship(deleteRule: .cascade, inverse: \StudySession.subject)
    var sessions: [StudySession]
    
    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sessions = []
    }
}
