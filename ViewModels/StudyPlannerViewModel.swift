import Foundation
import SwiftData
import Combine

@MainActor
final class StudyPlannerViewModel: ObservableObject {
    @Published var selectedSubject: Subject?
    @Published var studyTimeSeconds: TimeInterval = 25 * 60
    @Published var remainingTime: TimeInterval = 25 * 60
    @Published var isTimerActive = false
    @Published var timerMode: TimerMode = .study
    
    enum TimerMode {
        case study
        case breakTime
    }
    
    private var timerCancellable: AnyCancellable?
    /// Tracks the wall-clock time when the timer was last started/resumed,
    /// so we can compute real elapsed time even after the app returns from background.
    private var timerStartDate: Date?
    /// The remaining time snapshot when the timer was last started/resumed.
    private var remainingAtStart: TimeInterval = 0
    
    func startTimer() {
        isTimerActive = true
        timerStartDate = Date()
        remainingAtStart = remainingTime
        
        let title = timerMode == .study ? "Study Session Complete!" : "Break Time Over!"
        let body = timerMode == .study ? "Great work! Time for a short break." : "Ready to focus again?"
        NotificationManager.shared.scheduleActiveTimerNotification(title: title, body: body, after: remainingTime)
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let startDate = self.timerStartDate else { return }
                let elapsed = Date().timeIntervalSince(startDate)
                let newRemaining = max(0, self.remainingAtStart - elapsed)
                self.remainingTime = newRemaining
                if newRemaining <= 0 {
                    self.timerFinished()
                }
            }
    }
    
    func pauseTimer() {
        isTimerActive = false
        timerCancellable?.cancel()
        timerCancellable = nil
        timerStartDate = nil
        NotificationManager.shared.cancelActiveTimerNotification()
    }
    
    func resetTimer() {
        pauseTimer()
        remainingTime = timerMode == .study ? studyTimeSeconds : 5 * 60
    }
    
    func switchMode(to mode: TimerMode) {
        timerMode = mode
        resetTimer()
    }
    
    /// Resolve a subject by its persistent UUID from the given array.
    func resolveSubject(id: UUID?, from subjects: [Subject]) {
        guard let id = id else {
            selectedSubject = nil
            return
        }
        selectedSubject = subjects.first(where: { $0.id == id })
    }
    
    func addSubject(name: String, colorHex: String, context: ModelContext) {
        let subject = Subject(name: name, colorHex: colorHex)
        context.insert(subject)
        try? context.save()
    }
    
    func deleteSubject(_ subject: Subject, context: ModelContext) {
        if selectedSubject?.id == subject.id {
            selectedSubject = nil
        }
        context.delete(subject)
        try? context.save()
    }
    
    func logSession(duration: TimeInterval, notes: String, context: ModelContext) {
        guard let subject = selectedSubject else { return }
        let session = StudySession(duration: duration, date: Date(), notes: notes, subject: subject)
        context.insert(session)
        subject.sessions.append(session)
        try? context.save()
    }
    
    private func timerFinished() {
        pauseTimer()
        
        let title = timerMode == .study ? "Study Session Complete!" : "Break Time Over!"
        let body = timerMode == .study ? "Great work! Time for a short break." : "Ready to focus again?"
        NotificationManager.shared.scheduleTimerNotification(title: title, body: body, after: 0.1)
        
        if timerMode == .study {
            if let _ = selectedSubject {
                NotificationCenter.default.post(name: NSNotification.Name("StudySessionShouldLog"), object: studyTimeSeconds)
            }
            timerMode = .breakTime
            remainingTime = 5 * 60
        } else {
            timerMode = .study
            remainingTime = studyTimeSeconds
        }
    }
}
