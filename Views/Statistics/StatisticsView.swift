import SwiftUI
import Charts
import SwiftData

struct StatisticsView: View {
    @Query private var subjects: [Subject]
    @Query private var tasks: [TaskItem]
    @Query private var habits: [HabitItem]
    @Query private var sessions: [StudySession]
    
    @StateObject private var viewModel = StatisticsViewModel()
    
    private var totalStudyHours: Double {
        sessions.reduce(0.0) { $0 + $1.duration } / 3600.0
    }
    
    private var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var overallHabitCompliance: Double {
        guard !habits.isEmpty else { return 0.0 }
        let rates = viewModel.getHabitCompletionRates(habits: habits)
        let avgRate = rates.reduce(0.0) { $0 + $1.completionRate } / Double(rates.count)
        return avgRate
    }
    
    private var bestStreak: Int {
        habits.map { $0.streak }.max() ?? 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Summary Cards
                Section("Overview") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(title: "Study Hours", value: String(format: "%.1f", totalStudyHours), icon: "timer", color: .blue)
                        statCard(title: "Tasks Done", value: "\(completedTaskCount)/\(tasks.count)", icon: "checkmark.circle", color: .green)
                        statCard(title: "Habit Rate", value: String(format: "%.0f%%", overallHabitCompliance * 100), icon: "calendar", color: .purple)
                        statCard(title: "Best Streak", value: "\(bestStreak) days", icon: "flame.fill", color: .orange)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Study Hours per Subject") {
                    let studyStats = viewModel.getStudyHoursPerSubject(subjects: subjects)
                    if studyStats.isEmpty {
                        Text("Log study sessions in the Planner to populate charts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Chart(studyStats) { stat in
                            BarMark(
                                x: .value("Subject", stat.subjectName),
                                y: .value("Hours", stat.hours)
                            )
                            .foregroundStyle(Color(hex: stat.colorHex))
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                    }
                }
                
                Section("Weekly Task Completion") {
                    let taskStats = viewModel.getTasksCompletedPastWeek(tasks: tasks)
                    Chart(taskStats) { stat in
                        LineMark(
                            x: .value("Day", stat.dayOfWeek),
                            y: .value("Tasks Completed", stat.count)
                        )
                        .symbol(Circle())
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Day", stat.dayOfWeek),
                            y: .value("Tasks Completed", stat.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 200)
                }
                
                Section("Habit Completion Rates") {
                    let habitStats = viewModel.getHabitCompletionRates(habits: habits)
                    if habitStats.isEmpty {
                        Text("Add habits to populate compliance rates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Chart(habitStats) { stat in
                            BarMark(
                                x: .value("Habit", stat.habitName),
                                y: .value("Compliance Rate", stat.completionRate)
                            )
                            .foregroundStyle(Color.accentColor)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                    }
                }
            }
            .navigationTitle("Productivity Stats")
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}
