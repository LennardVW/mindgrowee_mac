import SwiftUI
import SwiftData

/// Errors that can occur during backup/restore
enum BackupError: Error {
    case invalidBackupFormat
    case unsupportedVersion
}

/// Automatic backup manager for local data protection
@MainActor
class AutoBackupManager: ObservableObject {
    static let shared = AutoBackupManager()
    
    @Published var lastBackupDate: Date?
    @Published var isBackingUp = false
    @Published var backupError: String?
    
    private let backupInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    private let backupDirectoryName = "MindGrowee_Backups"
    private let maxBackupCount = 7 // Keep 7 days of backups
    
    private init() {
        loadLastBackupDate()
        checkAndPerformBackup()
    }
    
    // MARK: - Backup Directory
    
    private func getBackupDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupDir = documentsPath.appendingPathComponent(backupDirectoryName)
        
        if !FileManager.default.fileExists(atPath: backupDir.path) {
            try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }
        
        return backupDir
    }
    
    // MARK: - Backup Logic
    
    private func loadLastBackupDate() {
        if let date = UserDefaults.standard.object(forKey: "lastAutoBackupDate") as? Date {
            lastBackupDate = date
        }
    }
    
    private func saveLastBackupDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "lastAutoBackupDate")
        lastBackupDate = date
    }
    
    func checkAndPerformBackup() {
        guard !isBackingUp else { return }
        
        let shouldBackup: Bool
        if let lastBackup = lastBackupDate {
            shouldBackup = Date().timeIntervalSince(lastBackup) >= backupInterval
        } else {
            shouldBackup = true
        }
        
        if shouldBackup {
            performBackup()
        }
    }
    
    func performBackup() {
        isBackingUp = true
        backupError = nil
        
        Task {
            do {
                try await createBackup()
                await MainActor.run {
                    saveLastBackupDate(Date())
                    isBackingUp = false
                    cleanupOldBackups()
                    Logger.shared.info("Auto-backup completed successfully")
                }
            } catch {
                await MainActor.run {
                    backupError = error.localizedDescription
                    isBackingUp = false
                    Logger.shared.error("Auto-backup failed", error: error)
                }
            }
        }
    }
    
    private func createBackup() async throws {
        // Export all data from SwiftData
        let container = try ModelContainer(for: Habit.self, JournalEntry.self, Project.self)
        let context = ModelContext(container)
        
        // Fetch all data
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let journalEntries = try context.fetch(FetchDescriptor<JournalEntry>())
        let projects = try context.fetch(FetchDescriptor<Project>())
        
        // Serialize to dictionaries
        let habitsData = habits.map { habit in
            [
                "id": habit.id.uuidString,
                "title": habit.title,
                "icon": habit.icon,
                "color": habit.color,
                "createdAt": ISO8601DateFormatter().string(from: habit.createdAt),
                "categoryId": habit.categoryId?.uuidString ?? NSNull()
            ]
        }
        
        let journalData = journalEntries.map { entry in
            [
                "id": entry.id.uuidString,
                "date": ISO8601DateFormatter().string(from: entry.date),
                "content": entry.content,
                "mood": entry.mood,
                "tags": entry.tags
            ]
        }
        
        let projectsData = projects.map { project in
            [
                "id": project.id.uuidString,
                "name": project.name,
                "projectDescription": project.projectDescription,
                "color": project.color,
                "icon": project.icon,
                "createdAt": ISO8601DateFormatter().string(from: project.createdAt),
                "deadline": project.deadline.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull(),
                "isCompleted": project.isCompleted,
                "completedAt": project.completedAt.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull()
            ]
        }
        
        // Create backup structure
        let backup: [String: Any] = [
            "version": 1,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "habits": habitsData,
            "journalEntries": journalData,
            "projects": projectsData
        ]
        
        // Serialize and save
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupName = "mindgrowee_backup_\(timestamp).json"
        let backupURL = getBackupDirectory().appendingPathComponent(backupName)
        
        let data = try JSONSerialization.data(withJSONObject: backup, options: .prettyPrinted)
        try data.write(to: backupURL)
        
        Logger.shared.info("Backup created: \(backupName) with \(habits.count) habits, \(journalEntries.count) entries, \(projects.count) projects")
    }
    
    private func cleanupOldBackups() {
        do {
            let backupDir = getBackupDirectory()
            let files = try FileManager.default.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            // Sort by creation date (newest first)
            let sortedFiles = files.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
            
            // Delete old backups
            if sortedFiles.count > maxBackupCount {
                let filesToDelete = sortedFiles.dropFirst(maxBackupCount)
                for file in filesToDelete {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            
        } catch {
            Logger.shared.error("Failed to cleanup old backups", error: error)
        }
    }
    
    // MARK: - Manual Backup
    
    func getAllBackups() -> [URL] {
        do {
            let backupDir = getBackupDirectory()
            let files = try FileManager.default.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            return files.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            return []
        }
    }
    
    func restoreFromBackup(_ url: URL) throws {
        Logger.shared.info("Restoring from backup: \(url.lastPathComponent)")
        
        // Read backup data
        let data = try Data(contentsOf: url)
        guard let backup = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BackupError.invalidBackupFormat
        }
        
        // Validate version
        guard let version = backup["version"] as? Int, version == 1 else {
            throw BackupError.unsupportedVersion
        }
        
        // Get model context
        let container = try ModelContainer(for: Habit.self, JournalEntry.self, Project.self)
        let context = ModelContext(container)
        
        let dateFormatter = ISO8601DateFormatter()
        
        // Restore habits
        if let habitsData = backup["habits"] as? [[String: Any]] {
            for habitDict in habitsData {
                guard let id = habitDict["id"] as? String,
                      let title = habitDict["title"] as? String,
                      let icon = habitDict["icon"] as? String,
                      let color = habitDict["color"] as? String,
                      let createdAtStr = habitDict["createdAt"] as? String,
                      let createdAt = dateFormatter.date(from: createdAtStr) else {
                    continue
                }
                
                let categoryId = (habitDict["categoryId"] as? String).flatMap { UUID(uuidString: $0) }
                
                let habit = Habit(title: title, icon: icon, color: color, categoryId: categoryId)
                habit.id = UUID(uuidString: id) ?? UUID()
                habit.createdAt = createdAt
                context.insert(habit)
            }
        }
        
        // Restore journal entries
        if let journalData = backup["journalEntries"] as? [[String: Any]] {
            for entryDict in journalData {
                guard let id = entryDict["id"] as? String,
                      let dateStr = entryDict["date"] as? String,
                      let date = dateFormatter.date(from: dateStr),
                      let content = entryDict["content"] as? String,
                      let mood = entryDict["mood"] as? Int,
                      let tags = entryDict["tags"] as? [String] else {
                    continue
                }
                
                let entry = JournalEntry(date: date, content: content, mood: mood, tags: tags)
                entry.id = UUID(uuidString: id) ?? UUID()
                context.insert(entry)
            }
        }
        
        // Restore projects
        if let projectsData = backup["projects"] as? [[String: Any]] {
            for projectDict in projectsData {
                guard let id = projectDict["id"] as? String,
                      let name = projectDict["name"] as? String,
                      let projectDescription = projectDict["projectDescription"] as? String,
                      let color = projectDict["color"] as? String,
                      let icon = projectDict["icon"] as? String,
                      let createdAtStr = projectDict["createdAt"] as? String,
                      let createdAt = dateFormatter.date(from: createdAtStr) else {
                    continue
                }
                
                let deadline = (projectDict["deadline"] as? String).flatMap { dateFormatter.date(from: $0) }
                let isCompleted = projectDict["isCompleted"] as? Bool ?? false
                let completedAt = (projectDict["completedAt"] as? String).flatMap { dateFormatter.date(from: $0) }
                
                let project = Project(name: name, description: projectDescription, color: color, icon: icon, deadline: deadline)
                project.id = UUID(uuidString: id) ?? UUID()
                project.createdAt = createdAt
                project.isCompleted = isCompleted
                project.completedAt = completedAt
                context.insert(project)
            }
        }
        
        // Save context
        try context.save()
        Logger.shared.info("Restore completed from: \(url.lastPathComponent)")
    }
    
    func deleteBackup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Backup Settings View

struct BackupSettingsView: View {
    @StateObject private var backupManager = AutoBackupManager.shared
    @State private var showingRestoreSheet = false
    @State private var backups: [URL] = []
    
    var body: some View {
        Form {
            Section("Automatic Backup") {
                Toggle("Enable Auto-Backup", isOn: .constant(true))
                
                if let lastBackup = backupManager.lastBackupDate {
                    HStack {
                        Text("Last Backup")
                        Spacer()
                        Text(lastBackup, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if backupManager.isBackingUp {
                    HStack {
                        Text("Backing up...")
                        Spacer()
                        ProgressView()
                    }
                }
                
                if let error = backupManager.backupError {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }
                
                Button("Backup Now") {
                    backupManager.performBackup()
                    loadBackups()
                }
                .disabled(backupManager.isBackingUp)
            }
            
            Section("Backup History") {
                if backups.isEmpty {
                    Text("No backups yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(backups, id: \.self) { backup in
                        HStack {
                            Image(systemName: "doc.fill")
                            
                            VStack(alignment: .leading) {
                                Text(backup.lastPathComponent)
                                    .font(.body)
                                
                                if let date = try? backup.resourceValues(forKeys: [.creationDateKey]).creationDate {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                backupManager.deleteBackup(backup)
                                loadBackups()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Section {
                Button("Restore from Backup...") {
                    showingRestoreSheet = true
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            loadBackups()
        }
    }
    
    private func loadBackups() {
        backups = backupManager.getAllBackups()
    }
}
