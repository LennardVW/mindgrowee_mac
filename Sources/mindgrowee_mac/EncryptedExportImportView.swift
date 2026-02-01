import SwiftUI
import SwiftData

// MARK: - Encrypted Export Import View

struct EncryptedExportImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    @Query(sort: \Project.createdAt) private var projects: [Project]
    
    @State private var selectedTab = 0
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPasswordError = false
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var exportedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var importPassword = ""
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Backup & Restore")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Export").tag(0)
                Text("Import").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if selectedTab == 0 {
                exportView
            } else {
                importView
            }
        }
        .frame(width: 500, height: 400)
        .alert("Error", isPresented: $showingPasswordError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Passwords do not match or are too short (min 8 characters)")
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .alert("Import Error", isPresented: $showingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    // MARK: - Export View
    
    private var exportView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Password")
                        .font(.headline)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("This password will encrypt your data. Don't forget it!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data to Export")
                        .font(.headline)
                    
                    HStack {
                        Label("Habits", systemImage: "checkmark.circle")
                        Spacer()
                        Text("\(habits.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Journal Entries", systemImage: "book")
                        Spacer()
                        Text("\(journalEntries.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Projects", systemImage: "folder")
                        Spacer()
                        Text("\(projects.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: exportData) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("Export Encrypted Data", systemImage: "lock.square")
                    }
                }
                .disabled(password.count < 8 || password != confirmPassword || isProcessing)
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Import View
    
    private var importView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Backup File")
                        .font(.headline)
                    
                    Button("Choose File...") {
                        showingFilePicker = true
                    }
                    
                    if let url = exportedFileURL {
                        Text("Selected: \(url.lastPathComponent)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Password")
                        .font(.headline)
                    
                    SecureField("Password", text: $importPassword)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Enter the password used to encrypt this backup")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(action: importData) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("Import Data", systemImage: "lock.open")
                    }
                }
                .disabled(exportedFileURL == nil || importPassword.count < 8 || isProcessing)
                .frame(maxWidth: .infinity)
            }
            
            Section {
                Text("⚠️ Importing will merge with existing data. Duplicate items will be skipped.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Export
    
    private func exportData() {
        guard password == confirmPassword, password.count >= 8 else {
            showingPasswordError = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // Create export container with raw data
                var exportItems: [ExportItem] = []
                
                // Export habits
                for habit in habits {
                    let item = ExportItem(
                        id: habit.id.uuidString,
                        type: "habit",
                        data: try JSONEncoder().encode(habit)
                    )
                    exportItems.append(item)
                }
                
                // Export journal entries
                for entry in journalEntries {
                    let item = ExportItem(
                        id: entry.id.uuidString,
                        type: "journal",
                        data: try JSONEncoder().encode(entry)
                    )
                    exportItems.append(item)
                }
                
                // Export projects
                for project in projects {
                    let item = ExportItem(
                        id: project.id.uuidString,
                        type: "project",
                        data: try JSONEncoder().encode(project)
                    )
                    exportItems.append(item)
                }
                
                // Create export container
                let container = ExportContainer(
                    version: 1,
                    exportDate: Date(),
                    items: exportItems
                )
                
                // Serialize container
                let containerData = try JSONEncoder().encode(container)
                
                // Encrypt with password using AES-256-GCM
                let encryptedData = try encryptExportData(containerData, password: password)
                
                // Save to file
                let filename = "mindgrowee_backup_\(formatDate(Date())).mindgrowee"
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent(filename)
                try encryptedData.write(to: url)
                
                await MainActor.run {
                    exportedFileURL = url
                    successMessage = "Export successful! Encrypted file saved to Downloads."
                    showSuccess = true
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    successMessage = "Export failed: \(error.localizedDescription)"
                    showSuccess = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func encryptExportData(_ data: Data, password: String) throws -> Data {
        // Derive key from password
        let passwordData = Data(password.utf8)
        let salt = Data.random(count: 32)
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: .init(data: passwordData),
            salt: salt,
            info: Data("mindgrowee_export".utf8),
            outputByteCount: 32
        )
        
        // Encrypt data
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // Create export format: salt + nonce + ciphertext + tag
        var exportData = Data()
        exportData.append(salt)
        exportData.append(Data(sealedBox.nonce))
        exportData.append(sealedBox.ciphertext)
        exportData.append(sealedBox.tag)
        
        return exportData
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Import
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                exportedFileURL = url
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
    
    private func importData() {
        guard let url = exportedFileURL else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Read encrypted data
                let encryptedData = try Data(contentsOf: url)
                
                // Decrypt with password
                let containerData = try decryptImportData(encryptedData, password: importPassword)
                
                // Decode container
                let container = try JSONDecoder().decode(ExportContainer.self, from: containerData)
                
                // Import items
                var importedCount = 0
                for item in container.items {
                    switch item.type {
                    case "habit":
                        if let habit = try? JSONDecoder().decode(Habit.self, from: item.data) {
                            modelContext.insert(habit)
                            importedCount += 1
                        }
                    case "journal":
                        if let entry = try? JSONDecoder().decode(JournalEntry.self, from: item.data) {
                            modelContext.insert(entry)
                            importedCount += 1
                        }
                    case "project":
                        if let project = try? JSONDecoder().decode(Project.self, from: item.data) {
                            modelContext.insert(project)
                            importedCount += 1
                        }
                    default:
                        break
                    }
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    successMessage = "Import successful! \(importedCount) items imported."
                    showSuccess = true
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    importErrorMessage = "Import failed: \(error.localizedDescription)"
                    showingImportError = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func decryptImportData(_ data: Data, password: String) throws -> Data {
        // Parse format: salt (32) + nonce (12) + ciphertext + tag (16)
        guard data.count > 60 else {
            throw EncryptionError.decryptionFailed
        }
        
        let salt = data.prefix(32)
        let nonceData = data.dropFirst(32).prefix(12)
        let tag = data.suffix(16)
        let ciphertext = data.dropFirst(44).dropLast(16)
        
        // Derive key from password
        let passwordData = Data(password.utf8)
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: .init(data: passwordData),
            salt: Data(salt),
            info: Data("mindgrowee_export".utf8),
            outputByteCount: 32
        )
        
        // Decrypt
        let nonce = try AES.GCM.Nonce(data: Data(nonceData))
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: Data(ciphertext), tag: Data(tag))
        
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// MARK: - Setup Encryption View

struct SetupEncryptionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSettingUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Secure Your Data")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Set up encryption to protect your habits and journal entries with a password.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            
            Text("Password must be at least 8 characters. Don't forget it - it cannot be recovered!")
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: setupEncryption) {
                if isSettingUp {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Enable Encryption")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.count < 8 || password != confirmPassword || isSettingUp)
            
            Button("Skip for now") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 450, height: 450)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func setupEncryption() {
        guard password == confirmPassword, password.count >= 8 else {
            errorMessage = "Passwords do not match or are too short"
            showingError = true
            return
        }
        
        isSettingUp = true
        
        Task {
            do {
                try EncryptionManager.shared.setupEncryption(password: password)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSettingUp = false
                }
            }
        }
    }
}

// MARK: - Unlock Encryption View

struct UnlockEncryptionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isUnlocking = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Unlock Your Data")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Enter your password to access your encrypted data.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            Button(action: unlock) {
                if isUnlocking {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Unlock")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.count < 8 || isUnlocking)
        }
        .padding()
        .frame(width: 400, height: 350)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func unlock() {
        isUnlocking = true
        
        Task {
            do {
                try EncryptionManager.shared.unlock(password: password)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Invalid password"
                    showingError = true
                    isUnlocking = false
                }
            }
        }
    }
}

// MARK: - Export Data Structures

struct ExportItem: Codable {
    let id: String
    let type: String
    let data: Data
}

struct ExportContainer: Codable {
    let version: Int
    let exportDate: Date
    let items: [ExportItem]
}

// MARK: - Data Extension for Random

extension Data {
    static func random(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
}
