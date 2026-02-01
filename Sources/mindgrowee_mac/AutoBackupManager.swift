import SwiftUI
import SwiftData

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
        // TODO: Implement actual backup logic
        // 1. Export all data
        // 2. Encrypt if needed
        // 3. Save to backup directory with timestamp
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupName = "mindgrowee_backup_\(timestamp).json"
        let backupURL = getBackupDirectory().appendingPathComponent(backupName)
        
        // Placeholder: Create empty file for now
        let placeholder = ["backup": true, "timestamp": timestamp] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: placeholder)
        try data.write(to: backupURL)
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
        // TODO: Implement restore logic
        Logger.shared.info("Restoring from backup: \(url.lastPathComponent)")
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
        .frame(width: 400, minHeight: 300)
        .onAppear {
            loadBackups()
        }
    }
    
    private func loadBackups() {
        backups = backupManager.getAllBackups()
    }
}
