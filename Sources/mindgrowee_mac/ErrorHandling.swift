import Foundation
import SwiftUI
import SwiftData

// MARK: - Error Recovery Manager

@MainActor
class ErrorRecoveryManager {
    static let shared = ErrorRecoveryManager()
    
    private init() {}
    
    /// Attempts to recover from a SwiftData error
    func recoverFromDataError(_ error: Error, context: ModelContext) -> ErrorRecoveryResult {
        Logger.shared.error("Data error occurred", error: error)
        
        if let swiftDataError = error as? SwiftDataError {
            switch swiftDataError {
            case .transactionFailure:
                // Try to rollback and retry
                context.rollback()
                return .recovered
                
            case .modelNotFound:
                // Entity was deleted, return failure
                return .failed(message: "Data not found. It may have been deleted.")
                
            case .validationFailed(let message):
                return .failed(message: "Validation failed: \(message)")
                
            @unknown default:
                return .failed(message: "Unknown data error occurred")
            }
        }
        
        // Generic error handling
        return .failed(message: error.localizedDescription)
    }
    
    /// Validates data before save
    func validateBeforeSave(context: ModelContext) -> ValidationResult {
        do {
            // Check for unsaved changes
            if context.hasChanges {
                // Try to validate
                try context.save()
                return .valid
            }
            return .noChanges
        } catch {
            Logger.shared.error("Validation failed", error: error)
            return .invalid(message: error.localizedDescription)
        }
    }
    
    /// Safely performs a data operation with error recovery
    func performDataOperation<T>(
        context: ModelContext,
        operation: () throws -> T
    ) -> Result<T, DataError> {
        do {
            let result = try operation()
            try context.save()
            return .success(result)
        } catch {
            context.rollback()
            Logger.shared.error("Data operation failed", error: error)
            return .failure(.operationFailed(message: error.localizedDescription))
        }
    }
    
    /// Safely fetches data with error handling
    func safeFetch<T: PersistentModel>(
        context: ModelContext,
        descriptor: FetchDescriptor<T>
    ) -> Result<[T], DataError> {
        do {
            let results = try context.fetch(descriptor)
            return .success(results)
        } catch {
            Logger.shared.error("Fetch failed", error: error)
            return .failure(.fetchFailed(message: error.localizedDescription))
        }
    }
}

// MARK: - Error Recovery Result

enum ErrorRecoveryResult {
    case recovered
    case failed(message: String)
}

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case noChanges
    case invalid(message: String)
}

// MARK: - Data Error

enum DataError: Error, LocalizedError {
    case operationFailed(message: String)
    case fetchFailed(message: String)
    case saveFailed(message: String)
    case validationFailed(message: String)
    case modelNotFound
    case corruptedData
    
    var errorDescription: String? {
        switch self {
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        case .fetchFailed(let message):
            return "Failed to load data: \(message)"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .modelNotFound:
            return "The requested item was not found"
        case .corruptedData:
            return "Data appears to be corrupted"
        }
    }
}

// MARK: - Swift Data Error (Placeholder for actual errors)

enum SwiftDataError: Error {
    case transactionFailure
    case modelNotFound
    case validationFailed(String)
}

// MARK: - Safe View Operations

extension View {
    /// Wraps a data operation with error handling
    func withErrorHandling(
        _ operation: @escaping () throws -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        do {
            try operation()
        } catch {
            Logger.shared.error("Operation failed", error: error)
            onError?(error)
        }
    }
}

// MARK: - Model Context Extensions

extension ModelContext {
    /// Safely inserts a model with validation
    func safeInsert<T: PersistentModel>(_ model: T) -> Result<Void, DataError> {
        do {
            insert(model)
            try save()
            return .success(())
        } catch {
            rollback()
            return .failure(.saveFailed(message: error.localizedDescription))
        }
    }
    
    /// Safely deletes a model
    func safeDelete<T: PersistentModel>(_ model: T) -> Result<Void, DataError> {
        do {
            delete(model)
            try save()
            return .success(())
        } catch {
            rollback()
            return .failure(.saveFailed(message: error.localizedDescription))
        }
    }
    
    /// Safely fetches with error handling
    func safeFetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> Result<[T], DataError> {
        do {
            let results = try fetch(descriptor)
            return .success(results)
        } catch {
            return .failure(.fetchFailed(message: error.localizedDescription))
        }
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: DataError?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func dataErrorAlert(error: Binding<DataError?>) -> some View {
        self.modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Crash Prevention

@MainActor
class CrashPrevention {
    static let shared = CrashPrevention()
    
    private init() {}
    
    /// Validates index bounds before access
    func safeArrayAccess<T>(array: [T], index: Int) -> T? {
        guard index >= 0, index < array.count else {
            Logger.shared.warning("Array index out of bounds: \(index), count: \(array.count)")
            return nil
        }
        return array[index]
    }
    
    /// Validates optional before force unwrapping
    func safeUnwrap<T>(_ optional: T?, defaultValue: T, context: String) -> T {
        guard let value = optional else {
            Logger.shared.warning("Unexpected nil in \(context), using default")
            return defaultValue
        }
        return value
    }
    
    /// Validates string before use
    func safeString(_ string: String?, defaultValue: String = "") -> String {
        guard let string = string, !string.isEmpty else {
            return defaultValue
        }
        return string
    }
}
