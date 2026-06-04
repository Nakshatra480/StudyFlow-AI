import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let note: NoteItem?
    
    @State private var title = ""
    @State private var content = ""
    @State private var category = "General"
    
    @State private var aiResponseText = ""
    @State private var isGenerating = false
    @State private var showingAIResponseSheet = false
    @State private var aiActionTitle = "AI Feedback"
    
    private var hasContent: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Title", text: $title)
                            .font(.title3)
                            .bold()
                        
                        Picker("Category", selection: $category) {
                            ForEach(["General", "Lectures", "Research", "Exams", "Personal"], id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    
                    Section("Note Content") {
                        TextEditor(text: $content)
                            .frame(minHeight: 300)
                    }
                }
                
                // Show AI buttons whenever content is non-empty (not just for existing notes)
                if hasContent {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: { runAIAction(prompt: "Summarize the following study note concisely with key takeaways:\n\n\(content)", title: "Summary") }) {
                                Label("Summarize", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { runAIAction(prompt: "Explain the following concept in simple terms with examples:\n\n\(content)", title: "Explanation") }) {
                                Label("Explain", systemImage: "book.pages")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { runAIAction(prompt: "Generate a multiple-choice quiz (4-5 questions) based on this study material. Include correct answers with brief explanations:\n\n\(content)", title: "Quiz") }) {
                            Label("Generate Quiz", systemImage: "questionmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
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
                        saveNote()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let note = note {
                    title = note.title
                    content = note.content
                    category = note.category
                }
            }
            .sheet(isPresented: $showingAIResponseSheet) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if isGenerating {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("AI is analyzing your note...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                            } else {
                                Text(LocalizedStringKey(aiResponseText))
                                    .padding()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .navigationTitle(aiActionTitle)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingAIResponseSheet = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        if let note = note {
            note.title = trimmedTitle
            note.content = content
            note.category = category
            note.updatedAt = Date()
        } else {
            let newNote = NoteItem(title: trimmedTitle, content: content, createdAt: Date(), updatedAt: Date(), category: category, isPinned: false)
            modelContext.insert(newNote)
        }
        
        try? modelContext.save()
    }
    
    private func runAIAction(prompt: String, title: String) {
        aiActionTitle = title
        isGenerating = true
        aiResponseText = ""
        showingAIResponseSheet = true
        
        Task {
            do {
                let response = try await AIService.shared.generateContent(prompt: prompt)
                await MainActor.run {
                    self.aiResponseText = response
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.aiResponseText = "⚠️ \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}
