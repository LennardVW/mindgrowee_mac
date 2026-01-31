import Foundation
import SwiftData

// MARK: - Backup Manager

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    @Published var lastBackupDate: Date?
    @Published var isBackingUp = false
    
    private let backupDirectoryName = "MindGroweeBackups"
    private let maxBackups = 10
    
    private var backupDirectory: URL? {
        guard let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(backupDirectoryName)
    }
    
    private init() {
        createBackupDirectory()
        loadLastBackupDate()
    }
    
    // MARK: - Backup
    
    func createBackup(habits: [Habit], entries: [JournalEntry]) -> Result<URL, Error> {
        isBackingUp = true
        defer { isBackingUp = false }
        
        guard let backupDir = backupDirectory else {
            return .failure(BackupError.directoryNotFound)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let backupFileName = "mindgrowee_backup_\(timestamp).json"
        let backupURL = backupDir.appendingPathComponent(backupFileName)
        
        // Create backup data
        let backupData = createBackupData(habits: habits, entries: entries)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
            try jsonData.write(to: backupURL)
            
            lastBackupDate = Date()
            saveLastBackupDate()
            
            // Clean old backups
            cleanupOldBackups()
            
            return .success(backupURL)
        } catch {
            return .failure(error)
        }
    }
    
    func createAutomaticBackup(habits: [Habit], entries: [JournalEntry]) {
        // Only backup if it's been more than 24 hours since last backup
        guard shouldAutoBackup() else { return }
        
        _ = createBackup(habits: habits, entries: entries)
    }
    
    // MARK: - Restore
    
    func restoreFromBackup(at url: URL) -> Result<BackupData, Error> {
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(BackupError.invalidData)
            }
            
            let backupData = try parseBackupData(json)
            return .success(backupData)
        } catch {
            return .failure(error)
        }
    }
    
    func listBackups() -> [URL] {
        guard let backupDir = backupDirectory else { return [] }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey])
            return files.filter { $0.pathExtension == "json" }.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func createBackupDirectory() {
        guard let backupDir = backupDirectory else { return }
        
        if !FileManager.default.fileExists(atPath: backupDir.path) {
            try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }
    }
    
    private func createBackupData(habits: [Habit], entries: [JournalEntry]) -> [String: Any] {
        var habitsData: [[String: Any]] = []
        
        for habit in habits {
            var habitDict: [String: Any] = [
                "id": habit.id.uuidString,
                "title": habit.title,
                "icon": habit.icon,
                "color": habit.color,
                "createdAt": ISO8601DateFormatter().string(from: habit.createdAt)
            ]
            
            var completionsData: [[String: Any]] = []
            for completion in habit.completions ?? [] {
                completionsData.append([
                    "date": ISO8601DateFormatter().string(from: completion.date),
                    "completed": completion.completed
                ])
            }
            habitDict["completions"] = completionsData
            habitsData.append(habitDict)
        }
        
        var entriesData: [[String: Any]] = []
        for entry in entries {
            entriesData.append([
                "id": entry.id.uuidString,
                "date": ISO8601DateFormatter().string(from: entry.date),
                "content": entry.content,
                "mood": entry.mood,
                "tags": entry.tags
            ])
        }
        
        return [
            "version": "1.0",
            "backupDate": ISO8601DateFormatter().string(from: Date()),
            "habits": habitsData,
            "journalEntries": entriesData
        ]
    }
    
    private func parseBackupData(_ json: [String: Any]) throws -> BackupData {
        // This would parse the backup and return structured data
        // For now, return empty data
        return BackupData(habits: [], entries: [])
    }
    
    private func shouldAutoBackup() -> Bool {
        guard let lastDate = lastBackupDate else { return true }
        let hoursSinceLastBackup = Date().timeIntervalSince(lastDate) / 3600
        return hoursSinceLastBackup >= 24
    }
    
    private func cleanupOldBackups() {
        let backups = listBackups()
        guard backups.count > maxBackups else { return }
        
        let backupsToDelete = backups.suffix(backups.count - maxBackups)
        for backup in backupsToDelete {
            try? FileManager.default.removeItem(at: backup)
        }
    }
    
    private func loadLastBackupDate() {
        if let date = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date {
            lastBackupDate = date
        }
    }
    
    private func saveLastBackupDate() {
        UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")
    }
}

// MARK: - Backup Data Structure

struct BackupData {
    let habits: [HabitBackupData]
    let entries: [JournalEntryBackupData]
}

struct HabitBackupData {
    let id: UUID
    let title: String
    let icon: String
    let color: String
    let createdAt: Date
    let completions: [CompletionBackupData]
}

struct CompletionBackupData {
    let date: Date
    let completed: Bool
}

struct JournalEntryBackupData {
    let id: UUID
    let date: Date
    let content: String
    let mood: Int
    let tags: [String]
}

// MARK: - Errors

enum BackupError: Error {
    case directoryNotFound
    case invalidData
    case backupFailed
}

extension BackupError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Could not find backup directory"
        case .invalidData:
            return "Backup data is invalid or corrupted"
        case .backupFailed:
            return "Failed to create backup"
        }
    }
}
