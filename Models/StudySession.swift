import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var duration: TimeInterval
    var date: Date
    var notes: String
    var subject: Subject?
    
    init(id: UUID = UUID(), duration: TimeInterval, date: Date = Date(), notes: String = "", subject: Subject? = nil) {
        self.id = id
        self.duration = duration
        self.date = date
        self.notes = notes
        self.subject = subject
    }
}
