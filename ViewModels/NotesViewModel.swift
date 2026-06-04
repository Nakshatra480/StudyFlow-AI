import Foundation
import SwiftData

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedCategory = "All"
    
    func addNote(title: String, content: String, category: String, context: ModelContext) {
        let note = NoteItem(title: title, content: content, createdAt: Date(), updatedAt: Date(), category: category, isPinned: false)
        context.insert(note)
        try? context.save()
    }
    
    func deleteNote(_ note: NoteItem, context: ModelContext) {
        context.delete(note)
        try? context.save()
    }
    
    func updateNote(_ note: NoteItem, title: String, content: String, category: String) {
        note.title = title
        note.content = content
        note.category = category
        note.updatedAt = Date()
        try? note.modelContext?.save()
    }
    
    func togglePin(for note: NoteItem) {
        note.isPinned.toggle()
        note.updatedAt = Date()
        try? note.modelContext?.save()
    }
    
    func filterAndSortNotes(_ notes: [NoteItem]) -> [NoteItem] {
        var filtered = notes
        
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) || $0.content.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        filtered.sort {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
        
        return filtered
    }
}
