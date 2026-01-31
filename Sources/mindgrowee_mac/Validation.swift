import Foundation

// MARK: - Validation Errors

enum ValidationError: Error, LocalizedError {
    case emptyHabitTitle
    case emptyJournalContent
    case invalidDate
    case duplicateHabitName
    
    var errorDescription: String? {
        switch self {
        case .emptyHabitTitle:
            return "Habit title cannot be empty"
        case .emptyJournalContent:
            return "Journal entry cannot be empty"
        case .invalidDate:
            return "Invalid date format"
        case .duplicateHabitName:
            return "A habit with this name already exists"
        }
    }
}

// MARK: - Data Validation

class DataValidator {
    static let shared = DataValidator()
    
    private init() {}
    
    func validateHabitTitle(_ title: String) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyHabitTitle
        }
    }
    
    func validateJournalContent(_ content: String) throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyJournalContent
        }
    }
    
    func validateDate(_ dateString: String, format: String = "yyyy-MM-dd") -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString) != nil
    }
    
    func isDuplicateHabitName(_ name: String, existingHabits: [Habit], excludingId: UUID? = nil) -> Bool {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        return existingHabits.contains { habit in
            guard habit.id != excludingId else { return false }
            return habit.title.lowercased().trimmingCharacters(in: .whitespaces) == normalizedName
        }
    }
}

// Import Habit for validation
import SwiftData

// MARK: - Error Handler

class ErrorHandler {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showError = false
    
    private init() {}
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = AppError(message: error.localizedDescription)
        }
        showError = true
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}

// MARK: - App Error

struct AppError: Identifiable {
    let id = UUID()
    let message: String
    let timestamp = Date()
}

// MARK: - Logger

class Logger {
    static let shared = Logger()
    
    private let isDebugMode: Bool
    
    private init() {
        #if DEBUG
        self.isDebugMode = true
        #else
        self.isDebugMode = false
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isDebugMode else { return }
        let filename = (file as NSString).lastPathComponent
        print("[DEBUG] \(filename):\(line) - \(function): \(message)")
    }
    
    func info(_ message: String) {
        print("[INFO] \(message)")
    }
    
    func warning(_ message: String) {
        print("[WARNING] \(message)")
    }
    
    func error(_ message: String, error: Error? = nil) {
        if let error = error {
            print("[ERROR] \(message): \(error.localizedDescription)")
        } else {
            print("[ERROR] \(message)")
        }
    }
}
