import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query private var habits: [HabitItem]
    @Query private var subjects: [Subject]
    
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var inputText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.messages.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("AI Study Assistant")
                            .font(.title2)
                            .bold()
                        
                        Text("Summarize notes, build interactive quizzes, make flashcards, or ask complex concept breakdowns.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 12) {
                            Button(action: { submitQuickPrompt("Generate a 3-question quiz on cellular biology.") }) {
                                quickActionLabel("Generate Quiz", systemImage: "questionmark.circle")
                            }
                            
                            Button(action: { submitQuickPrompt("Create flashcards for learning core concepts of Newton's Laws.") }) {
                                quickActionLabel("Make Flashcards", systemImage: "square.text.square")
                            }
                            
                            Button(action: { submitQuickPrompt("Explain the difference between SQL and NoSQL databases like I am five.") }) {
                                quickActionLabel("Explain Concept", systemImage: "lightbulb")
                            }
                            
                            Button(action: { submitQuickPrompt("Based on my current study progress, give me a personalized study plan for today.") }) {
                                quickActionLabel("Study Plan", systemImage: "calendar.badge.clock")
                            }
                        }
                        .padding(.top)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    HStack {
                                        if message.isUser {
                                            Spacer()
                                            Text(message.text)
                                                .padding()
                                                .background(Color.accentColor)
                                                .foregroundColor(.white)
                                                .cornerRadius(16)
                                                .padding(.leading, 60)
                                        } else {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(LocalizedStringKey(message.text))
                                                    .textSelection(.enabled)
                                            }
                                            .padding()
                                            .background(Color.secondarySystemGroupedBackground)
                                            .cornerRadius(16)
                                            .padding(.trailing, 60)
                                            Spacer()
                                        }
                                    }
                                    .id(message.id)
                                }
                                
                                if viewModel.isGenerating {
                                    HStack {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                            Text("Thinking...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.secondarySystemGroupedBackground)
                                        .cornerRadius(16)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    TextField("Ask anything...", text: $inputText, axis: .vertical)
                        .padding(12)
                        .background(Color.secondarySystemGroupedBackground)
                        .cornerRadius(12)
                        .lineLimit(1...4)
                    
                    Button(action: submitMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.accentColor)
                            .clipShape(Circle())
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                }
                .padding()
                .background(Color.systemBackground)
            }
            .navigationTitle("AI Assistant")
            .toolbar {
                if !viewModel.messages.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear") {
                            viewModel.clearMessages()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.updateContext(tasks: tasks, habits: habits, subjects: subjects)
            }
        }
    }
    
    private func quickActionLabel(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func submitMessage() {
        let text = inputText
        inputText = ""
        viewModel.updateContext(tasks: tasks, habits: habits, subjects: subjects)
        Task {
            await viewModel.sendMessage(text)
        }
    }
    
    private func submitQuickPrompt(_ prompt: String) {
        viewModel.updateContext(tasks: tasks, habits: habits, subjects: subjects)
        Task {
            await viewModel.sendMessage(prompt)
        }
    }
}
