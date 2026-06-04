import SwiftUI
import SwiftData

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [HabitItem]
    
    @StateObject private var viewModel = HabitTrackerViewModel()
    @State private var showingAddHabit = false
    @State private var newHabitTitle = ""
    @State private var selectedFrequency: HabitFrequency = .daily
    
    var body: some View {
        NavigationStack {
            List {
                Section("My Habits") {
                    if habits.isEmpty {
                        Text("No habits registered yet. Add one below.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(habits) { habit in
                            HabitRowView(
                                habit: habit,
                                isCompletedToday: viewModel.isHabitCompletedToday(habit),
                                onToggle: {
                                    viewModel.toggleHabitCompletion(habit, date: Date(), context: modelContext)
                                }
                            )
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deleteHabit(habit, context: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Habit Tracker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                NavigationStack {
                    Form {
                        TextField("Habit Title", text: $newHabitTitle)
                        
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(HabitFrequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                    }
                    .navigationTitle("New Habit")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddHabit = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                viewModel.addHabit(title: newHabitTitle, frequency: selectedFrequency, context: modelContext)
                                newHabitTitle = ""
                                showingAddHabit = false
                            }
                            .disabled(newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }
}
