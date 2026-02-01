import SwiftUI
import SwiftData

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBar") private var showMenuBar = true
    @AppStorage("showDockIcon") private var showDockIcon = true
    @AppStorage("soundEffects") private var soundEffects = true
    @AppStorage("streakGoal") private var streakGoal = 7
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("accentColor") private var accentColor = "blue"
    
    private var resolvedAccent: Color {
        switch accentColor {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    @State private var showingImport = false
    @State private var showingClearData = false
    @State private var showingReset = false
    
    private struct AccentColorOption: Identifiable {
        let id: String
        let color: Color
    }

    private let accentColors: [AccentColorOption] = [
        AccentColorOption(id: "red", color: .red),
        AccentColorOption(id: "orange", color: .orange),
        AccentColorOption(id: "yellow", color: .yellow),
        AccentColorOption(id: "green", color: .green),
        AccentColorOption(id: "blue", color: .blue),
        AccentColorOption(id: "purple", color: .purple),
        AccentColorOption(id: "pink", color: .pink)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            
            List {
                // Appearance Section
                Section("Appearance") {
                    Toggle("Use System Appearance", isOn: $useSystemAppearance)
                    
                    if !useSystemAppearance {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                    
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(accentColors) { option in
                                Button(action: { accentColor = option.id }) {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(accentColor == option.id ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // General Section
                Section("General") {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                    
                    Toggle("Show in Menu Bar", isOn: $showMenuBar)
                    
                    Toggle("Show Dock Icon", isOn: $showDockIcon)
                    
                    Toggle("Sound Effects", isOn: $soundEffects)
                }
                
                // Goals Section
                Section("Goals") {
                    HStack {
                        Text("Streak Goal")
                        Spacer()
                        Picker("", selection: $streakGoal) {
                            ForEach([3, 7, 14, 21, 30, 60, 90], id: \.self) { days in
                                Text("\(days) days").tag(days)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
                
                // Data Section
                Section("Data") {
                    Button("Import Data...") {
                        showingImport = true
                    }
                    
                    Button("Export Data...") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .showExport, object: nil)
                        }
                    }
                    
                    Button("Reset Today's Progress") {
                        showingReset = true
                    }
                    .foregroundStyle(.orange)
                    
                    Button("Clear All Data") {
                        showingClearData = true
                    }
                    .foregroundStyle(.red)
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Data Storage")
                        Spacer()
                        Text("Local (SwiftData)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/LennardVW/mindgrowee_mac")!)
                }
            }
            .listStyle(.inset)
            
            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .padding()
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingImport) {
            EncryptedExportImportView()
        }
        .tint(resolvedAccent)
        .accentColor(resolvedAccent)
        .alert("Reset Today's Progress?", isPresented: $showingReset) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetTodayProgress()
            }
        } message: {
            Text("This will mark all habits as incomplete for today. This cannot be undone.")
        }
        .alert("Clear All Data?", isPresented: $showingClearData) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all habits, completions, and journal entries. This cannot be undone.")
        }
    }
    
    private func resetTodayProgress() {
        let today = startOfDay(Date())
        let descriptor = FetchDescriptor<DailyCompletion>()
        
        do {
            let completions = try modelContext.fetch(descriptor)
            for completion in completions {
                if isSameDay(completion.date, today) {
                    modelContext.delete(completion)
                }
            }
        } catch {
            Logger.shared.error("Failed to reset progress", error: error)
        }
    }
    
    private func clearAllData() {
        // Delete all habits (cascade deletes completions)
        let habitDescriptor = FetchDescriptor<Habit>()
        do {
            let habits = try modelContext.fetch(habitDescriptor)
            for habit in habits {
                modelContext.delete(habit)
            }
        } catch {
            Logger.shared.error("Failed to clear habits", error: error)
        }
        
        // Delete all journal entries
        let entryDescriptor = FetchDescriptor<JournalEntry>()
        do {
            let entries = try modelContext.fetch(entryDescriptor)
            for entry in entries {
                modelContext.delete(entry)
            }
        } catch {
            Logger.shared.error("Failed to clear journal entries", error: error)
        }
    }
}

// MARK: - Import View

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var importText = ""
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var showingResult = false
    
    enum ImportResult {
        case success(habits: Int, entries: Int)
        case error(message: String)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Data")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Paste JSON data or import from file")
                .foregroundStyle(.secondary)
            
            TextEditor(text: $importText)
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            HStack {
                Button("Choose File...") {
                    showingFilePicker = true
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Import") {
                    importFromText()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(importText.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 500, height: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        importText = try String(contentsOf: url, encoding: .utf8)
                    } catch {
                        importResult = .error(message: "Failed to read file: \(error.localizedDescription)")
                        showingResult = true
                    }
                }
            case .failure(let error):
                importResult = .error(message: "Failed to select file: \(error.localizedDescription)")
                showingResult = true
            }
        }
        .alert("Import Result", isPresented: $showingResult) {
            Button("OK") {
                if case .success = importResult {
                    dismiss()
                }
            }
        } message: {
            switch importResult {
            case .success(let habits, let entries):
                Text("Successfully imported \(habits) habits and \(entries) journal entries.")
            case .error(let message):
                Text(message)
            case .none:
                Text("")
            }
        }
    }
    
    private func importFromText() {
        guard let data = importText.data(using: .utf8) else {
            importResult = .error(message: "Invalid text encoding")
            showingResult = true
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var habitsImported = 0
                var entriesImported = 0
                
                // Import habits
                if let habitsData = json["habits"] as? [[String: Any]] {
                    for habitDict in habitsData {
                        if let idString = habitDict["id"] as? String,
                           let id = UUID(uuidString: idString),
                           let title = habitDict["title"] as? String,
                           let icon = habitDict["icon"] as? String,
                           let color = habitDict["color"] as? String {
                            
                            let habit = Habit(title: title, icon: icon, color: color)
                            habit.id = id
                            
                            if let createdAtString = habitDict["created_at"] as? String,
                               let createdAt = ISO8601DateFormatter().date(from: createdAtString) {
                                habit.createdAt = createdAt
                            }
                            
                            modelContext.insert(habit)
                            habitsImported += 1
                            
                            // Import completions for this habit
                            if let completionsData = habitDict["completions"] as? [[String: Any]] {
                                for compDict in completionsData {
                                    if let dateString = compDict["date"] as? String,
                                       let date = ISO8601DateFormatter().date(from: dateString),
                                       let completed = compDict["completed"] as? Bool {
                                        let completion = DailyCompletion(date: date, completed: completed, habit: habit)
                                        modelContext.insert(completion)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Import journal entries
                if let entriesData = json["journal_entries"] as? [[String: Any]] {
                    for entryDict in entriesData {
                        if let idString = entryDict["id"] as? String,
                           let id = UUID(uuidString: idString),
                           let dateString = entryDict["date"] as? String,
                           let date = ISO8601DateFormatter().date(from: dateString),
                           let content = entryDict["content"] as? String,
                           let mood = entryDict["mood"] as? Int {
                            
                            let tags = entryDict["tags"] as? [String] ?? []
                            let entry = JournalEntry(date: date, content: content, mood: mood, tags: tags)
                            entry.id = id
                            modelContext.insert(entry)
                            entriesImported += 1
                        }
                    }
                }
                
                importResult = .success(habits: habitsImported, entries: entriesImported)
            } else {
                importResult = .error(message: "Invalid JSON format")
            }
        } catch {
            importResult = .error(message: "Failed to parse JSON: \(error.localizedDescription)")
        }
        
        showingResult = true
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let showExport = Notification.Name("showExport")
    static let showSettings = Notification.Name("showSettings")
}
