import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "settings_dark_mode")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "settings_notifications_enabled")
        }
    }
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "gemini_api_key")
        }
    }
    
    var isAPIKeyConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "settings_dark_mode")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "settings_notifications_enabled")
        self.apiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? AIService.defaultAPIKey
    }
    
    func resetAllData(context: ModelContext) {
        do {
            try context.delete(model: TaskItem.self)
            try context.delete(model: NoteItem.self)
            try context.delete(model: HabitLog.self)
            try context.delete(model: HabitItem.self)
            try context.delete(model: StudySession.self)
            try context.delete(model: Subject.self)
            try context.save()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
    
    func exportData(tasks: [TaskItem], notes: [NoteItem], habits: [HabitItem], subjects: [Subject]) -> Data? {
        struct ExportPayload: Codable {
            struct TaskDTO: Codable {
                let title: String
                let notes: String
                let dueDate: Date
                let priority: String
                let isCompleted: Bool
                let category: String
            }
            struct NoteDTO: Codable {
                let title: String
                let content: String
                let createdAt: Date
                let category: String
                let isPinned: Bool
            }
            struct HabitDTO: Codable {
                let title: String
                let frequency: String
                let streak: Int
            }
            struct SubjectDTO: Codable {
                let name: String
                let colorHex: String
                let sessionCount: Int
            }
            let exportDate: Date
            let tasks: [TaskDTO]
            let notes: [NoteDTO]
            let habits: [HabitDTO]
            let subjects: [SubjectDTO]
        }
        
        let payload = ExportPayload(
            exportDate: Date(),
            tasks: tasks.map { ExportPayload.TaskDTO(title: $0.title, notes: $0.notes, dueDate: $0.dueDate, priority: $0.priority.rawValue, isCompleted: $0.isCompleted, category: $0.category) },
            notes: notes.map { ExportPayload.NoteDTO(title: $0.title, content: $0.content, createdAt: $0.createdAt, category: $0.category, isPinned: $0.isPinned) },
            habits: habits.map { ExportPayload.HabitDTO(title: $0.title, frequency: $0.frequency.rawValue, streak: $0.streak) },
            subjects: subjects.map { ExportPayload.SubjectDTO(name: $0.name, colorHex: $0.colorHex, sessionCount: $0.sessions.count) }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(payload)
    }
}
