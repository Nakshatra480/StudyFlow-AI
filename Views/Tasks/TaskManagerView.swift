import SwiftUI
import SwiftData

struct TaskManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    
    @StateObject private var viewModel = TaskManagerViewModel()
    @State private var showingAddTask = false
    @State private var selectedTaskForEditing: TaskItem? = nil
    
    var filteredTasks: [TaskItem] {
        viewModel.filterAndSortTasks(tasks)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search tasks...", text: $viewModel.searchQuery)
                }
                .padding(10)
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(10)
                .padding()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { viewModel.selectedCategory = "All" }) {
                            Text("All")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedCategory == "All" ? Color.accentColor : Color.secondary.opacity(0.1))
                                .foregroundColor(viewModel.selectedCategory == "All" ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(["General", "Study", "Assignment", "Exam", "Personal"], id: \.self) { category in
                            Button(action: { viewModel.selectedCategory = category }) {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewModel.selectedCategory == category ? Color.accentColor : Color.secondary.opacity(0.1))
                                    .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                List {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task, onToggleCompletion: {
                            viewModel.toggleCompletion(for: task, context: modelContext)
                        })
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTaskForEditing = task
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteTask(task, context: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
            .navigationTitle("Task Manager")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortBy) {
                            ForEach(TaskManagerViewModel.TaskSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                TaskDetailView(task: nil)
            }
            .sheet(item: $selectedTaskForEditing) { task in
                TaskDetailView(task: task)
            }
        }
    }
}

#Preview {
    TaskManagerView()
        .modelContainer(PreviewSampleData.container)
}

