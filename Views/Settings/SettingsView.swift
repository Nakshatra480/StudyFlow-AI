import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @Query private var notes: [NoteItem]
    @Query private var habits: [HabitItem]
    @Query private var subjects: [Subject]
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExportSheet = false
    @State private var exportData: Data? = nil
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                    
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) {
                            if viewModel.notificationsEnabled {
                                NotificationManager.shared.requestPermission()
                            }
                        }
                }
                
                Section {
                    SecureField("Gemini API Key", text: $viewModel.apiKey)
                    
                    HStack {
                        Image(systemName: viewModel.isAPIKeyConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(viewModel.isAPIKeyConfigured ? .green : .orange)
                        
                        Text(viewModel.isAPIKeyConfigured ? "API Key configured — AI is live" : "No API Key — AI will not function")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your Gemini API key is stored locally on this device and never shared. It enables real-time AI-powered study assistance.")
                }
                
                Section("Data Management") {
                    Button(action: triggerExport) {
                        Label("Export Local Data (JSON)", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: { showingResetConfirmation = true }) {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Platform")
                        Spacer()
                        #if os(iOS)
                        Text("iOS \(UIDevice.current.systemVersion)")
                            .foregroundColor(.secondary)
                        #else
                        Text("macOS")
                            .foregroundColor(.secondary)
                        #endif
                    }
                    
                    HStack {
                        Text("Data")
                        Spacer()
                        Text("\(tasks.count) tasks · \(notes.count) notes · \(habits.count) habits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Everything", role: .destructive) {
                    viewModel.resetAllData(context: modelContext)
                }
            } message: {
                Text("This will permanently delete all tasks, notes, habits, subjects, and study sessions. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                #if os(iOS)
                if let data = exportData {
                    ActivityView(activityItems: [data])
                }
                #else
                VStack(spacing: 16) {
                    Text("Export Data")
                        .font(.headline)
                    Text("Data export is supported natively on iOS.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Close") {
                        showingExportSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                #endif
            }
        }
    }
    
    private func triggerExport() {
        if let data = viewModel.exportData(tasks: tasks, notes: notes, habits: habits, subjects: subjects) {
            self.exportData = data
            self.showingExportSheet = true
        }
    }
}

#if os(iOS)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
