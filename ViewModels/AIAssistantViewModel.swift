import Foundation
import SwiftData

@MainActor
final class AIAssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isGenerating = false
    @Published var currentText = ""
    @Published var error: String? = nil
    
    // Study context for personalized AI
    var taskCount: Int = 0
    var habitStreak: Int = 0
    var subjectNames: [String] = []
    
    struct AIMessage: Identifiable {
        let id: UUID
        let text: String
        let isUser: Bool
        let timestamp: Date
        
        init(text: String, isUser: Bool) {
            self.id = UUID()
            self.text = text
            self.isUser = isUser
            self.timestamp = Date()
        }
    }
    
    func updateContext(tasks: [TaskItem], habits: [HabitItem], subjects: [Subject]) {
        self.taskCount = tasks.filter { !$0.isCompleted }.count
        self.habitStreak = habits.map { $0.streak }.max() ?? 0
        self.subjectNames = subjects.map { $0.name }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMsg = AIMessage(text: text, isUser: true)
        messages.append(userMsg)
        error = nil
        isGenerating = true
        
        do {
            let response = try await AIService.shared.generateContentWithContext(
                prompt: text,
                taskCount: taskCount,
                habitStreak: habitStreak,
                subjects: subjectNames
            )
            let aiMsg = AIMessage(text: response, isUser: false)
            messages.append(aiMsg)
        } catch {
            self.error = error.localizedDescription
            let errorMsg = AIMessage(text: "⚠️ \(error.localizedDescription)", isUser: false)
            messages.append(errorMsg)
        }
        
        isGenerating = false
    }
    
    func clearMessages() {
        messages.removeAll()
        error = nil
    }
}
