import SwiftUI
import SwiftData

/// Centralized error handling and recovery system
@MainActor
class ErrorRecoveryManager: ObservableObject {
    static let shared = ErrorRecoveryManager()
    
    @Published var currentError: RecoverableError?
    @Published var isRecovering = false
    @Published var recoverySuggestion: String?
    
    private init() {}
    
    // MARK: - Error Types
    
    enum RecoverableError: Identifiable {
        case databaseError(Error)
        case encryptionError(Error)
        case importError(Error)
        case exportError(Error)
        case networkError(Error)
        case unknownError(Error)
        
        var id: String {
            switch self {
            case .databaseError: return "database"
            case .encryptionError: return "encryption"
            case .importError: return "import"
            case .exportError: return "export"
            case .networkError: return "network"
            case .unknownError: return "unknown"
            }
        }
        
        var title: String {
            switch self {
            case .databaseError: return "Database Error"
            case .encryptionError: return "Encryption Error"
            case .importError: return "Import Failed"
            case .exportError: return "Export Failed"
            case .networkError: return "Network Error"
            case .unknownError: return "Something Went Wrong"
            }
        }
        
        var message: String {
            switch self {
            case .databaseError(let error):
                return "Failed to save your data: \(error.localizedDescription)"
            case .encryptionError(let error):
                return "Encryption operation failed: \(error.localizedDescription)"
            case .importError(let error):
                return "Could not import data: \(error.localizedDescription)"
            case .exportError(let error):
                return "Could not export data: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network request failed: \(error.localizedDescription)"
            case .unknownError(let error):
                return error.localizedDescription
            }
        }
        
        var canRecover: Bool {
            switch self {
            case .databaseError, .encryptionError:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: ModelContext? = nil) {
        Logger.shared.error("Recoverable error occurred", error: error)
        
        let recoverableError: RecoverableError
        
        if let encryptionError = error as? EncryptionError {
            recoverableError = .encryptionError(encryptionError)
        } else if let updateError = error as? UpdateError {
            recoverableError = .networkError(updateError)
        } else {
            recoverableError = .unknownError(error)
        }
        
        currentError = recoverableError
        recoverySuggestion = suggestRecovery(for: recoverableError)
    }
    
    private func suggestRecovery(for error: RecoverableError) -> String? {
        switch error {
        case .databaseError:
            return "Try restarting the app. If the problem persists, restore from a backup."
        case .encryptionError:
            return "Check if you entered the correct password. You may need to reset encryption."
        case .importError:
            return "Make sure the file is not corrupted and you have the correct password."
        case .exportError:
            return "Ensure you have enough disk space and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknownError:
            return "Try restarting the app."
        }
    }
    
    // MARK: - Recovery Actions
    
    func attemptRecovery(context: ModelContext?) {
        guard let error = currentError else { return }
        
        isRecovering = true
        
        Task {
            do {
                switch error {
                case .databaseError:
                    try await recoverFromDatabaseError(context: context)
                case .encryptionError:
                    try await recoverFromEncryptionError()
                default:
                    break
                }
                
                await MainActor.run {
                    isRecovering = false
                    currentError = nil
                    recoverySuggestion = nil
                }
                
            } catch {
                await MainActor.run {
                    isRecovering = false
                    Logger.shared.error("Recovery failed", error: error)
                }
            }
        }
    }
    
    private func recoverFromDatabaseError(context: ModelContext?) async throws {
        // Try to rollback any pending changes
        context?.rollback()
        
        // Wait a moment
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Try to save again
        try context?.save()
    }
    
    private func recoverFromEncryptionError() async throws {
        // Reset encryption state
        EncryptionManager.shared.reset()
        
        // Wait a moment
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func dismissError() {
        currentError = nil
        recoverySuggestion = nil
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @StateObject private var errorManager = ErrorRecoveryManager.shared
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if let error = errorManager.currentError {
                VStack(spacing: 16) {
                    Image(systemName: errorIcon(for: error))
                        .font(.system(size: 50))
                        .foregroundStyle(errorColor(for: error))
                    
                    Text(error.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(error.message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    if let suggestion = errorManager.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if error.canRecover {
                        Button(action: {
                            errorManager.attemptRecovery(context: modelContext)
                        }) {
                            if errorManager.isRecovering {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Try to Recover")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(errorManager.isRecovering)
                    }
                    
                    Button("Dismiss") {
                        errorManager.dismissError()
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .frame(width: 400)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 10)
            }
        }
    }
    
    private func errorIcon(for error: ErrorRecoveryManager.RecoverableError) -> String {
        switch error {
        case .databaseError: return "externaldrive.fill.badge.xmark"
        case .encryptionError: return "lock.slash.fill"
        case .importError, .exportError: return "arrow.up.arrow.down.circle.fill"
        case .networkError: return "wifi.slash"
        case .unknownError: return "exclamationmark.triangle.fill"
        }
    }
    
    private func errorColor(for error: ErrorRecoveryManager.RecoverableError) -> Color {
        switch error {
        case .databaseError: return .red
        case .encryptionError: return .orange
        case .importError, .exportError: return .blue
        case .networkError: return .yellow
        case .unknownError: return .gray
        }
    }
}

// MARK: - View Modifier

struct ErrorAlertModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                ErrorAlertView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .ignoresSafeArea()
            )
    }
}

extension View {
    func withErrorAlert() -> some View {
        modifier(ErrorAlertModifier())
    }
}
