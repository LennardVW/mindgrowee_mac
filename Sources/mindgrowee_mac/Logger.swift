import Foundation

/// Centralized logging system for MindGrowee
/// Logs to console and file for debugging
class Logger {
    static let shared = Logger()
    
    private let logFile: URL
    private let dateFormatter: DateFormatter
    private let fileManager = FileManager.default
    
    private init() {
        // Setup log file in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appFolder = appSupport.appendingPathComponent("MindGrowee", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appFolder.path) {
            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        logFile = appFolder.appendingPathComponent("mindgrowee.log")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Clean old logs (keep last 7 days)
        cleanOldLogs()
    }
    
    // MARK: - Log Levels
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("DEBUG", message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("INFO", message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("WARNING", message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log("ERROR", message: fullMessage, file: file, function: function, line: line)
    }
    
    // MARK: - Private Logging
    
    private func log(_ level: String, message: String, file: String, function: String, line: Int) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logEntry = "[\(timestamp)] [\(level)] [\(fileName):\(line)] \(function) - \(message)\n"
        
        // Print to console
        print(logEntry, terminator: "")
        
        // Write to file
        appendToFile(logEntry)
    }
    
    private func appendToFile(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        if fileManager.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                _ = fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
    
    // MARK: - Log Management
    
    private func cleanOldLogs() {
        // Rotate log if > 10MB
        if let attributes = try? fileManager.attributesOfItem(atPath: logFile.path),
           let size = attributes[.size] as? UInt64,
           size > 10_000_000 {
            rotateLog()
        }
    }
    
    private func rotateLog() {
        let rotatedLog = logFile.deletingPathExtension()
            .appendingPathExtension("old.log")
        
        try? fileManager.removeItem(at: rotatedLog)
        try? fileManager.moveItem(at: logFile, to: rotatedLog)
    }
    
    func exportLogs() -> String? {
        try? String(contentsOf: logFile, encoding: .utf8)
    }
    
    func clearLogs() {
        try? fileManager.removeItem(at: logFile)
    }
}

// MARK: - Encryption Logger Extension

extension Logger {
    func logEncryptionSetup() {
        info("🔐 Encryption setup completed")
    }
    
    func logEncryptionUnlock() {
        info("🔓 Encryption unlocked")
    }
    
    func logEncryptionError(_ error: Error) {
        error("Encryption operation failed", error: error)
    }
    
    func logDataExport(recordCount: Int) {
        info("📤 Exported \(recordCount) encrypted records")
    }
    
    func logDataImport(recordCount: Int) {
        info("📥 Imported \(recordCount) encrypted records")
    }
    
    func logBackupCreated() {
        info("💾 Auto-backup created")
    }
    
    func logBackupRestored() {
        info("📂 Backup restored")
    }
}

// MARK: - Performance Logger Extension

extension Logger {
    func logPerformance(operation: String, duration: TimeInterval) {
        if duration > 1.0 {
            warning("⏱️ \(operation) took \(String(format: "%.2f", duration))s")
        } else {
            debug("⏱️ \(operation) took \(String(format: "%.3f", duration))s")
        }
    }
    
    func measure<T>(operation: String, _ block: () throws -> T) rethrows -> T {
        let start = Date()
        defer {
            logPerformance(operation: operation, duration: Date().timeIntervalSince(start))
        }
        return try block()
    }
}
