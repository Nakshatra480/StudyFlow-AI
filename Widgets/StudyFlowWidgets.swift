import WidgetKit
import SwiftUI

struct TaskWidgetEntry: TimelineEntry {
    let date: Date
    let taskTitle: String
    let dueDateString: String
    let hasTask: Bool
}

struct TaskWidgetProvider: TimelineProvider {
    private let defaults = UserDefaults.standard
    
    func placeholder(in context: Context) -> TaskWidgetEntry {
        TaskWidgetEntry(date: Date(), taskTitle: "Your Next Task", dueDateString: "Due soon", hasTask: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskWidgetEntry) -> Void) {
        let entry = fetchCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchCurrentEntry() -> TaskWidgetEntry {
        let title = defaults.string(forKey: "widget_next_task_title")
        let dueDateString = defaults.string(forKey: "widget_next_task_due")
        
        if let title = title, !title.isEmpty {
            return TaskWidgetEntry(
                date: Date(),
                taskTitle: title,
                dueDateString: dueDateString ?? "No due date",
                hasTask: true
            )
        } else {
            return TaskWidgetEntry(
                date: Date(),
                taskTitle: "All caught up!",
                dueDateString: "No pending tasks",
                hasTask: false
            )
        }
    }
}

struct TaskWidgetEntryView: View {
    var entry: TaskWidgetProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.accentColor)
                Text("StudyFlow")
                    .font(.caption)
                    .bold()
            }
            
            Spacer()
            
            if entry.hasTask {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Text(entry.taskTitle)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(2)
            
            Text(entry.dueDateString)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct StudyFlowWidget: Widget {
    let kind: String = "StudyFlowWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskWidgetProvider()) { entry in
            TaskWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Task Widget")
        .description("Shows your next upcoming task from StudyFlow AI.")
        .supportedFamilies([.systemSmall])
    }
}
