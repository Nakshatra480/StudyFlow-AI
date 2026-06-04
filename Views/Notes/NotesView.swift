import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [NoteItem]
    
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNote = false
    @State private var selectedNoteForEditing: NoteItem? = nil
    
    var filteredNotes: [NoteItem] {
        viewModel.filterAndSortNotes(notes)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search notes...", text: $viewModel.searchQuery)
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
                        
                        ForEach(["General", "Lectures", "Research", "Exams", "Personal"], id: \.self) { category in
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
                
                if filteredNotes.isEmpty {
                    Spacer()
                    ContentUnavailableView("No Notes Found", systemImage: "note.text", description: Text("Try searching something else or create a new note."))
                    Spacer()
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        if note.isPinned {
                                            Image(systemName: "pin.fill")
                                                .font(.caption)
                                                .foregroundColor(.accentColor)
                                        }
                                        Text(note.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text(note.content)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    
                                    HStack {
                                        Text(note.category)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.1))
                                            .cornerRadius(4)
                                        
                                        Spacer()
                                        
                                        Text(note.updatedAt, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedNoteForEditing = note
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.togglePin(for: note)
                                } label: {
                                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteNote(note, context: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddNote = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                NoteDetailView(note: nil)
            }
            .sheet(item: $selectedNoteForEditing) { note in
                NoteDetailView(note: note)
            }
        }
    }
}

#Preview {
    NotesView()
        .modelContainer(PreviewSampleData.container)
}

