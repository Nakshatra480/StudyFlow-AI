import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query private var habits: [HabitItem]
    @Query private var subjects: [Subject]
    @Query private var sessions: [StudySession]
    @Query private var notes: [NoteItem]
    
    @StateObject private var taskViewModel = TaskManagerViewModel()
    @State private var showingAddTask = false
    @State private var showingAddNote = false
    @State private var selectedTab: Int?
    
    var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { !$0.isCompleted && calendar.isDateInToday($0.dueDate) }
    }
    
    var todayStudyHours: Double {
        let calendar = Calendar.current
        let todaySessions = sessions.filter { calendar.isDateInToday($0.date) }
        return todaySessions.reduce(0.0) { $0 + $1.duration } / 3600.0
    }
    
    var habitProgress: (completed: Int, total: Int) {
        let calendar = Calendar.current
        let total = habits.count
        let completed = habits.filter { habit in
            habit.logs.contains { calendar.isDateInToday($0.date) && $0.isCompleted }
        }.count
        return (completed, total)
    }
    
    var maxStreak: Int {
        habits.map { $0.streak }.max() ?? 0
    }
    
    var completedTasksToday: Int {
        let calendar = Calendar.current
        return tasks.filter { $0.isCompleted && calendar.isDateInToday($0.dueDate) }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Your Study Flow")
                                .font(.title)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DashboardCard(title: "Study Hours", systemImage: "timer") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "%.1f %@", todayStudyHours, todayStudyHours == 1.0 ? "hr" : "hrs"))
                                    .font(.title2)
                                    .bold()
                                Text("focused today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        DashboardCard(title: "Habits Done", systemImage: "calendar") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(habitProgress.completed)/\(habitProgress.total)")
                                    .font(.title2)
                                    .bold()
                                CustomProgressView(progress: habitProgress.total > 0 ? Double(habitProgress.completed) / Double(habitProgress.total) : 0.0)
                            }
                        }
                        
                        DashboardCard(title: "Tasks Left", systemImage: "checkmark.circle") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(todayTasks.count)")
                                    .font(.title2)
                                    .bold()
                                Text("\(completedTasksToday) done today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        DashboardCard(title: "Current Streak", systemImage: "flame") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(maxStreak) \(maxStreak == 1 ? "Day" : "Days")")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.orange)
                                Text("keep it up!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Today's Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Tasks")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if todayTasks.isEmpty {
                            Text("All caught up! No tasks due today. 🎉")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(Color.secondarySystemGroupedBackground)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(todayTasks.prefix(5)) { task in
                                    TaskRowView(task: task, onToggleCompletion: {
                                        taskViewModel.toggleCompletion(for: task, context: modelContext)
                                    })
                                    .padding()
                                    
                                    if task.id != todayTasks.prefix(5).last?.id {
                                        Divider().padding(.horizontal)
                                    }
                                }
                            }
                            .background(Color.secondarySystemGroupedBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                Button(action: { showingAddTask = true }) {
                                    Label("Add Task", systemImage: "plus")
                                        .padding()
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                
                                Button(action: { showingAddNote = true }) {
                                    Label("New Note", systemImage: "note.text.badge.plus")
                                        .padding()
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: StudyPlannerView()) {
                                    Label("Start Study", systemImage: "timer")
                                        .padding()
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                
                                NavigationLink(destination: AIAssistantView()) {
                                    Label("Ask AI", systemImage: "sparkles")
                                        .padding()
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Activity Summary
                    if !notes.isEmpty || !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                if let latestNote = notes.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
                                    HStack {
                                        Image(systemName: "note.text")
                                            .foregroundColor(.accentColor)
                                        VStack(alignment: .leading) {
                                            Text(latestNote.title)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Text("Last edited \(latestNote.updatedAt.timeAgo())")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                                
                                if let latestSession = sessions.sorted(by: { $0.date > $1.date }).first {
                                    HStack {
                                        Image(systemName: "timer")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading) {
                                            Text("\(latestSession.subject?.name ?? "Study") — \(Int(latestSession.duration / 60)) min")
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Text(latestSession.date.timeAgo())
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 12)
                            .background(Color.secondarySystemGroupedBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.systemGroupedBackground)
            .sheet(isPresented: $showingAddTask) {
                TaskDetailView(task: nil)
            }
            .sheet(isPresented: $showingAddNote) {
                NoteDetailView(note: nil)
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌇"
        default: return "Night Owl 🌙"
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewSampleData.container)
}
