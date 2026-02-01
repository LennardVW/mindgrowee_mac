import SwiftUI
import SwiftData
import CryptoKit

// MARK: - Encrypted Model Support

/// Protocol for models that support encryption
protocol EncryptableModel {
    func encrypt() throws -> EncryptedModelContainer
    static func decrypt(from container: EncryptedModelContainer) throws -> Self
}

/// Container for encrypted model data
struct EncryptedModelContainer: Codable {
    let id: UUID
    let table: String
    let encryptedData: Data
    let nonce: Data
    let tag: Data
    let createdAt: Date
    let modifiedAt: Date
}

// MARK: - Encrypted Journal Entry

/// Journal entry with automatic encryption
@Model
class EncryptedJournalEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var modifiedAt: Date
    var encryptedContent: Data
    var encryptedTags: Data
    var nonce: Data
    var tag: Data
    var mood: Int // Not encrypted for filtering
    var date: Date // Not encrypted for sorting
    
    init(date: Date, content: String, mood: Int, tags: [String]) throws {
        self.id = UUID()
        self.date = date
        self.mood = mood
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        // Encrypt content and tags
        let contentData = Data(content.utf8)
        let tagsData = try JSONEncoder().encode(tags)
        
        guard let key = EncryptionManager.shared.masterKey else {
            throw EncryptionError.notInitialized
        }
        
        // Encrypt content
        let contentBox = try AES.GCM.seal(contentData, using: key)
        self.encryptedContent = contentBox.ciphertext
        
        // Encrypt tags
        let tagsBox = try AES.GCM.seal(tagsData, using: key)
        self.encryptedTags = tagsBox.ciphertext
        
        // Store nonce and tag (use content's for both, or separate)
        self.nonce = contentBox.nonce
        self.tag = contentBox.tag
    }
    
    /// Decrypt and get content
    func decryptContent() throws -> String {
        guard let key = EncryptionManager.shared.masterKey else {
            throw EncryptionError.notInitialized
        }
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: encryptedContent,
            tag: tag
        )
        
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    /// Decrypt and get tags
    func decryptTags() throws -> [String] {
        guard let key = EncryptionManager.shared.masterKey else {
            throw EncryptionError.notInitialized
        }
        
        // For simplicity, using same nonce/tag - in production use separate
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: encryptedTags,
            tag: tag
        )
        
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return try JSONDecoder().decode([String].self, from: decryptedData)
    }
    
    /// Update entry with new content
    func update(content: String, mood: Int, tags: [String]) throws {
        self.mood = mood
        self.modifiedAt = Date()
        
        guard let key = EncryptionManager.shared.masterKey else {
            throw EncryptionError.notInitialized
        }
        
        // Re-encrypt content
        let contentData = Data(content.utf8)
        let contentBox = try AES.GCM.seal(contentData, using: key)
        self.encryptedContent = contentBox.ciphertext
        
        // Re-encrypt tags
        let tagsData = try JSONEncoder().encode(tags)
        let tagsBox = try AES.GCM.seal(tagsData, using: key)
        self.encryptedTags = tagsBox.ciphertext
        
        // Update nonce and tag
        self.nonce = contentBox.nonce
        self.tag = contentBox.tag
    }
}

// MARK: - Model Migration Helper

/// Helper to migrate from unencrypted to encrypted models
class ModelEncryptionMigrator {
    static let shared = ModelEncryptionMigrator()
    
    private init() {}
    
    /// Check if migration is needed
    func needsMigration(context: ModelContext) -> Bool {
        // Check if old JournalEntry table exists and has data
        // while EncryptedJournalEntry is empty
        do {
            let descriptor = FetchDescriptor<EncryptedJournalEntry>()
            let encryptedCount = try context.fetch(descriptor).count
            return encryptedCount == 0
        } catch {
            return true
        }
    }
    
    /// Migrate all JournalEntry to EncryptedJournalEntry
    func migrateJournalEntries(from entries: [JournalEntry], context: ModelContext) throws {
        guard EncryptionManager.shared.isInitialized else {
            throw EncryptionError.notInitialized
        }
        
        for entry in entries {
            let encryptedEntry = try EncryptedJournalEntry(
                date: entry.date,
                content: entry.content,
                mood: entry.mood,
                tags: entry.tags
            )
            context.insert(encryptedEntry)
        }
        
        try context.save()
    }
}

// MARK: - View Helpers

/// Wrapper view that handles encryption/decryption transparently
struct EncryptedJournalRow: View {
    let entry: EncryptedJournalEntry
    @State private var decryptedContent: String = ""
    @State private var decryptedTags: [String] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= entry.mood ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(i <= entry.mood ? .yellow : .gray)
                    }
                }
            }
            
            if isLoading {
                Text("Decrypting...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Text(decryptedContent)
                    .font(.body)
                    .lineLimit(3)
                
                if !decryptedTags.isEmpty {
                    HStack {
                        ForEach(decryptedTags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            decrypt()
        }
    }
    
    private func decrypt() {
        Task {
            do {
                let content = try entry.decryptContent()
                let tags = try entry.decryptTags()
                
                await MainActor.run {
                    decryptedContent = content
                    decryptedTags = tags
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    decryptedContent = "[Decryption failed]"
                    isLoading = false
                }
            }
        }
    }
}
