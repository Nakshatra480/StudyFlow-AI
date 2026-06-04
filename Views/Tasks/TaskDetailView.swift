import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let task: TaskItem?
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var priority: TaskPriority = .medium
    @State private var category = "General"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Details") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { prio in
                            Text(prio.rawValue).tag(prio)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(["General", "Study", "Assignment", "Exam", "Personal"], id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let task = task {
                    title = task.title
                    notes = task.notes
                    dueDate = task.dueDate
                    priority = task.priority
                    category = task.category
                }
            }
        }
    }
    
    private func saveTask() {
        if let task = task {
            task.title = title
            task.notes = notes
            task.dueDate = dueDate
            task.priority = priority
            task.category = category
            
            NotificationManager.shared.cancelTaskNotification(for: task)
            if !task.isCompleted {
                NotificationManager.shared.scheduleTaskNotification(for: task)
            }
        } else {
            let newTask = TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority, isCompleted: false, category: category)
            modelContext.insert(newTask)
            NotificationManager.shared.scheduleTaskNotification(for: newTask)
        }
        
        try? modelContext.save()
        TaskManagerViewModel.syncWidgetData(context: modelContext)
    }
}
