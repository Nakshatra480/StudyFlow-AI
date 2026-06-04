import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Text(task.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                        
                    Text(task.dueDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(task.priority.rawValue)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor(task.priority).opacity(0.1))
                .foregroundColor(priorityColor(task.priority))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
    
    private func priorityColor(_ p: TaskPriority) -> Color {
        switch p {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}
