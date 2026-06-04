import SwiftUI
import SwiftData

struct StudyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subjects: [Subject]
    @Query(sort: \StudySession.date, order: .reverse) private var sessions: [StudySession]
    
    @StateObject private var viewModel = StudyPlannerViewModel()
    @State private var showingAddSubject = false
    @State private var newSubjectName = ""
    @State private var newSubjectColor = "#4A90E2"
    @State private var showingTimer = false
    @State private var selectedDuration: TimeInterval = 25 * 60
    @State private var selectedSubjectID: UUID? = nil
    
    private let durationOptions: [(String, TimeInterval)] = [
        ("15 min", 15 * 60),
        ("25 min", 25 * 60),
        ("30 min", 30 * 60),
        ("45 min", 45 * 60),
        ("60 min", 60 * 60)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Active Subjects") {
                    if subjects.isEmpty {
                        Text("No subjects registered yet. Register below.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(subjects) { subject in
                            HStack {
                                Circle()
                                    .fill(Color(hex: subject.colorHex))
                                    .frame(width: 12, height: 12)
                                
                                Text(subject.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(subject.sessions.count) \(subject.sessions.count == 1 ? "session" : "sessions")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    let totalHours = subject.sessions.reduce(0.0) { $0 + $1.duration } / 3600.0
                                    if totalHours > 0 {
                                        Text(String(format: "%.1f %@", totalHours, totalHours == 1.0 ? "hr" : "hrs"))
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    if selectedSubjectID == subject.id {
                                        selectedSubjectID = nil
                                    }
                                    viewModel.deleteSubject(subject, context: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingAddSubject = true }) {
                        Label("Add Subject", systemImage: "plus")
                    }
                }
                
                Section("Focus Session") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Select Subject", selection: $selectedSubjectID) {
                            Text("Select Subject").tag(nil as UUID?)
                            ForEach(subjects) { subj in
                                Text(subj.name).tag(subj.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedSubjectID) {
                            viewModel.resolveSubject(id: selectedSubjectID, from: subjects)
                        }
                        
                        // Duration picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(durationOptions, id: \.1) { option in
                                        Button(action: {
                                            selectedDuration = option.1
                                            viewModel.studyTimeSeconds = option.1
                                            viewModel.resetTimer()
                                        }) {
                                            Text(option.0)
                                                .font(.subheadline)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(selectedDuration == option.1 ? Color.accentColor : Color.secondary.opacity(0.1))
                                                .foregroundColor(selectedDuration == option.1 ? .white : .primary)
                                                .cornerRadius(16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            viewModel.resolveSubject(id: selectedSubjectID, from: subjects)
                            viewModel.studyTimeSeconds = selectedDuration
                            viewModel.resetTimer()
                            showingTimer = true
                        }) {
                            Label("Open Study Timer", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedSubjectID == nil ? Color.secondary.opacity(0.3) : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(selectedSubjectID == nil)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Recent History") {
                    if sessions.isEmpty {
                        Text("No study sessions logged yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(sessions.prefix(10)) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.subject?.name ?? "Unknown Subject")
                                        .font(.subheadline)
                                        .bold()
                                    
                                    if !session.notes.isEmpty {
                                        Text(session.notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    let minsVal = session.duration / 60.0
                                    Text(String(format: "%.0f %@", minsVal, minsVal == 1.0 ? "min" : "mins"))
                                        .font(.subheadline)
                                        .bold()
                                    Text(session.date, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Study Planner")
            .sheet(isPresented: $showingAddSubject) {
                NavigationStack {
                    Form {
                        TextField("Subject Name", text: $newSubjectName)
                        
                        Picker("Select Color", selection: $newSubjectColor) {
                            Text("Blue").tag("#4A90E2")
                            Text("Green").tag("#2ECC71")
                            Text("Red").tag("#E74C3C")
                            Text("Orange").tag("#F39C12")
                            Text("Purple").tag("#9B59B6")
                            Text("Teal").tag("#1ABC9C")
                            Text("Pink").tag("#E91E63")
                        }
                    }
                    .navigationTitle("New Subject")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddSubject = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                viewModel.addSubject(name: newSubjectName, colorHex: newSubjectColor, context: modelContext)
                                newSubjectName = ""
                                showingAddSubject = false
                            }
                            .disabled(newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTimer) {
                TimerView(viewModel: viewModel)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
