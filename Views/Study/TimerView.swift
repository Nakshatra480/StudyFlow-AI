import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var viewModel: StudyPlannerViewModel
    @State private var sessionNotes = ""
    @State private var showingLogAlert = false
    
    var timeString: String {
        let minutes = Int(viewModel.remainingTime) / 60
        let seconds = Int(viewModel.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        let total = viewModel.timerMode == .study ? viewModel.studyTimeSeconds : 5 * 60
        guard total > 0 else { return 0.0 }
        return 1.0 - (viewModel.remainingTime / total)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Text(viewModel.timerMode == .study ? "Study Session" : "Short Break")
                    .font(.title)
                    .bold()
                
                TimerRingView(progress: progress, timeString: timeString)
                
                HStack(spacing: 24) {
                    Button(action: {
                        if viewModel.isTimerActive {
                            viewModel.pauseTimer()
                        } else {
                            viewModel.startTimer()
                        }
                    }) {
                        Label(viewModel.isTimerActive ? "Pause" : "Start", systemImage: viewModel.isTimerActive ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    Button(action: {
                        viewModel.resetTimer()
                    }) {
                        Label("Reset", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                    }
                }
                
                if viewModel.timerMode == .study {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Notes (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("What are you working on?", text: $sessionNotes)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: {
                    if viewModel.timerMode == .study && progress > 0.05 {
                        showingLogAlert = true
                    } else {
                        dismiss()
                    }
                }) {
                    Text("Close & Complete")
                        .foregroundColor(.red)
                }
                .padding(.bottom)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .interactiveDismissDisabled(viewModel.timerMode == .study && progress > 0.05)
            .alert("Log Session?", isPresented: $showingLogAlert) {
                Button("Discard") {
                    dismiss()
                }
                Button("Log & Close") {
                    let elapsed = (viewModel.timerMode == .study ? viewModel.studyTimeSeconds : 5 * 60) - viewModel.remainingTime
                    viewModel.logSession(duration: elapsed, notes: sessionNotes, context: modelContext)
                    dismiss()
                }
            } message: {
                Text("Would you like to save this focus session in history?")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StudySessionShouldLog"))) { notification in
                if let duration = notification.object as? TimeInterval {
                    viewModel.logSession(duration: duration, notes: sessionNotes, context: modelContext)
                }
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
            .onDisappear {
                viewModel.pauseTimer()
            }
        }
    }
}
