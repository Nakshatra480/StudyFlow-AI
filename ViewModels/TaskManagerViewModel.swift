import Foundation
import SwiftData
import WidgetKit

@MainActor
final class TaskManagerViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedPriority: TaskPriority? = nil
    @Published var selectedCategory = "All"
    @Published var sortBy: TaskSortOption = .dueDate
    
    enum TaskSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case alphabetical = "Title"
    }
    
    func addTask(title: String, notes: String, dueDate: Date, priority: TaskPriority, category: String, context: ModelContext) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let task = TaskItem(title: trimmedTitle, notes: notes, dueDate: dueDate, priority: priority, isCompleted: false, category: category)
        context.insert(task)
        try? context.save()
        NotificationManager.shared.scheduleTaskNotification(for: task)
        Self.syncWidgetData(context: context)
    }
    
    func deleteTask(_ task: TaskItem, context: ModelContext) {
        NotificationManager.shared.cancelTaskNotification(for: task)
        context.delete(task)
        try? context.save()
        Self.syncWidgetData(context: context)
    }
    
    func toggleCompletion(for task: TaskItem, context: ModelContext) {
        task.isCompleted.toggle()
        if task.isCompleted {
            NotificationManager.shared.cancelTaskNotification(for: task)
        } else {
            NotificationManager.shared.scheduleTaskNotification(for: task)
        }
        try? context.save()
        Self.syncWidgetData(context: context)
    }
    
    func filterAndSortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        var filtered = tasks
        
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) || $0.notes.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        switch sortBy {
        case .dueDate:
            filtered.sort { $0.dueDate < $1.dueDate }
        case .priority:
            filtered.sort { 
                let p1 = priorityVal($0.priority)
                let p2 = priorityVal($1.priority)
                return p1 > p2
            }
        case .alphabetical:
            filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return filtered
    }
    
    /// Sync the next upcoming task to UserDefaults for the widget
    static func syncWidgetData(context: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        do {
            let upcomingTasks = try context.fetch(descriptor)
            let defaults = UserDefaults.standard
            
            if let nextTask = upcomingTasks.first {
                defaults.set(nextTask.title, forKey: "widget_next_task_title")
                
                let formatter = DateFormatter()
                let calendar = Calendar.current
                if calendar.isDateInToday(nextTask.dueDate) {
                    formatter.dateFormat = "'Today,' h:mm a"
                } else if calendar.isDateInTomorrow(nextTask.dueDate) {
                    formatter.dateFormat = "'Tomorrow,' h:mm a"
                } else {
                    formatter.dateFormat = "MMM d, h:mm a"
                }
                defaults.set(formatter.string(from: nextTask.dueDate), forKey: "widget_next_task_due")
            } else {
                defaults.removeObject(forKey: "widget_next_task_title")
                defaults.removeObject(forKey: "widget_next_task_due")
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to sync widget data: \(error)")
        }
    }
    
    private func priorityVal(_ p: TaskPriority) -> Int {
        switch p {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}
