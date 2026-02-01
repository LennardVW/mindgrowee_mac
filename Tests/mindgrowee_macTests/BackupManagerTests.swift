import XCTest
import SwiftData
@testable import mindgrowee_mac

@MainActor
final class BackupManagerTests: XCTestCase {
    
    var backupManager: AutoBackupManager!
    
    override func setUp() {
        super.setUp()
        backupManager = AutoBackupManager.shared
    }
    
    override func tearDown() {
        backupManager = nil
        super.tearDown()
    }
    
    // MARK: - Backup Tests
    
    func testBackupDirectoryCreation() {
        // Given
        let backupDir = backupManager.getBackupDirectory()
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupDir.path))
    }
    
    // MARK: - Restore Tests
    
    func testRestoreInvalidBackupFormat() {
        // Given - invalid data
        let invalidData = Data("invalid json".utf8)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invalid_backup.json")
        try? invalidData.write(to: tempURL)
        
        // Then - should throw error
        XCTAssertThrowsError(try backupManager.restoreFromBackup(tempURL)) { error in
            XCTAssertTrue(error is BackupError)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testRestoreUnsupportedVersion() {
        // Given - valid JSON but unsupported version
        let invalidBackup: [String: Any] = [
            "version": 999,
            "timestamp": "2026-01-01T00:00:00Z"
        ]
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invalid_version.json")
        let data = try! JSONSerialization.data(withJSONObject: invalidBackup)
        try? data.write(to: tempURL)
        
        // Then - should throw error
        XCTAssertThrowsError(try backupManager.restoreFromBackup(tempURL)) { error in
            XCTAssertEqual(error as? BackupError, BackupError.unsupportedVersion)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Cleanup Tests
    
    func testMaxBackupCount() {
        // Given
        let maxCount = 7
        
        // Then - verify max count is set correctly
        XCTAssertEqual(backupManager.maxBackupCount, maxCount)
    }
    
    // MARK: - Date Helper Tests
    
    func testStartOfDay() {
        // Given
        let date = Date()
        let startOfDay = startOfDay(date)
        
        // Then - should be midnight of that day
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }
    
    func testIsSameDay() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Then
        XCTAssertTrue(isSameDay(today, today))
        XCTAssertFalse(isSameDay(today, yesterday))
    }
}
